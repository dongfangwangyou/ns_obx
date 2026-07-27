[简体中文](ARCHITECTURE_CN.md)

# ns_obx Architecture

This document describes the internal dependency-tracking and reactive data-flow design of `ns_obx`.
It is intended for maintainers and advanced users who need a deep understanding of Obx / Rx
behavior. For API usage, see [README.md](README.md).

---

## 1. Design Goals

| Goal                        | Approach                                                                                                                                          |
|-----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| GetX-compatible             | `.obs`, `Obx`, `RxList/Map/Set` public APIs stay consistent                                                                                       |
| Precise rebuild             | Field-level dependencies; stale Rx values automatically detach after conditional branch switches                                                  |
| Subscriptions kept separate | **Proxy dependencies** (Obx reads `.value`) and **upstream subscriptions** (`bindStream`, `select`) are managed in separate tables                |
| Low overhead                | Signal skips notification when it has no listeners; Obx merges `setState` within the same frame; incremental sweep replaces full `clearListeners` |

---

## 2. Layer Overview

```
                    RxInterface (RxProxyContract + static proxy)
                              │
         ┌────────────────────┴────────────────────┐
         ▼                                         ▼
   Rx Publisher Side                       Obx Observer Side
   RxSubjectMixin                                ObxObserver
         │                              (proxy dependency table + sweep)
         │                                         │
         └──────── subject / listen ◄──────── attach / rebuild
                              │
                    Signal (event primitive)
```

### Module Responsibilities

| Module              | File                            | Responsibility                                                               |
|---------------------|---------------------------------|------------------------------------------------------------------------------|
| **Signal**          | `signals/signal.dart`           | Synchronous event broadcast; stores `value`; no buffer                       |
| **RxProxyContract** | `rx/core/rx_interface.dart`     | Instance contract: dependency registration + listen / close                  |
| **RxSubjectMixin**  | `rx/core/rx_subject_mixin.dart` | Publisher-side `subject`, `listen()` (no proxy dependency table)             |
| **ReactiveMixin**   | `rx/core/reactive_mixin.dart`   | `value`, `bindStream`, `linkSubscription`                                    |
| **RxCollection**    | `rx/types/rx_collection.dart`   | Collection base class + `RxCondition`; `readTracked` / `evaluateCondition`   |
| **ObxObserver**     | `obx/obx_observer.dart`         | Proxy dependency table + sweep + rebuild                                     |
| **ObxState**        | `obx/obx_widget.dart`           | Holds `ObxObserver`; sweep wraps builder; same-frame `scheduleFrameCallback` |

---

## 3. Two Kinds of Subscriptions (Core Distinction)

### 3.1 Proxy Dependencies (ObxObserver Only)

When an `Obx` rebuild executes `count.value`:

1. `notifyDependents` points `RxInterface.proxy` to the current `ObxObserver` (stacked push/restore,
   no public setter).
2. The Rx getter calls `proxy.addListener(subject)`.
3. `ObxObserver.addListener(signal)` → `_dispatch()`.

**Rx data nodes have no proxy dependency table**; `addListener` / `clearListeners` are no-ops on the
Rx side.

### 3.2 Upstream Subscriptions (via linkSubscription)

`bindStream`, `select`, and listens to a parent Rx are registered via
`ReactiveMixin.linkSubscription` into `_linkedSubscriptions`, and **do not enter** `_dependencies`.

Reason: if they were mixed into the same table, Obx's `endDependencySweep` would mistakenly cancel
`bindStream`, causing the Rx to stop synchronizing with the external Stream.

```
bindStream(stream)  →  stream.listen(...)  →  linkSubscription(sub)
select(parent)      →  parent.listen(...)  →  linkSubscription(sub)
```

`close()` cancels both linked subscriptions and proxy dependencies together.

---

## 4. Responsibility Boundary Between Rx and Obx

|                        | Rx (Publisher) | ObxObserver (Observer)               |
|------------------------|----------------|--------------------------------------|
| Proxy dependency table | None           | `_dependencies` (inside ObxObserver) |
| `canUpdate`            | Always `false` | `_dependencies.isNotEmpty`           |
| `addListener`          | No-op          | attach → rebuild                     |
| Value-change outlet    | `subject`      | `_dispatch()`                        |

---

## 5. Obx Rebuild and Incremental Sweep

`sweep` is implemented by **ObxObserver**; Rx data nodes do not call it.

Each `Obx` rebuild flow (`ObxState.build`):

```
beginDependencySweep()     // snapshot the current key set of _dependencies
  builder()                // read .value → retainDependency + attach when needed
endDependencySweep()       // detach keys that remain from the snapshot
```

Compared with the old full `clearListeners()` every frame:

- Unchanged dependencies **keep** their original `StreamSubscription`, avoiding repeated attach.
- After a conditional branch switch, Rx values that are no longer read are **automatically**
  detached (stale-dependency fix).

Business code usually does not need to call the APIs above; tests or manual resets can use
`clearListeners()`.

---

## 6. Same-Frame Rebuild Merging

When multiple Rx values call `subject.add` continuously within the same frame,
`ObxObserver._dispatch` merges those notifications into **one** `setState` via
`SchedulerBinding.scheduleFrameCallback`.

Typical scenarios: batch assignments such as `loading` + `error`, or multiple linked Rx values after
`list.update`.

---

## 7. Typical Data Flows

### 7.1 User Changes Value → Obx Updates

```
count.value++
  → ReactiveMixin setter → subject.emit(newValue)
       ├─ ObxObserver (already attached) → scheduleFrameCallback → setState
       └─ rx.listen(subject)            → Worker / side effect (not via dependency table)
```

### 7.2 Obx Build Registers Dependencies

```
Obx builder executes count.value
  → getter sees proxy != null → proxy.addListener(count.subject)
  → ObxObserver.addListener(count.subject) → rebuild
```

### 7.3 bindStream + Obx on the Same Page

```
externalStream → bindStream → value setter → subject.add
                                                  ↓
                                       Obx reads this Rx → rebuild

Obx conditional branch no longer reads this Rx → sweep only detaches Obx-side proxy
bindStream's linkSubscription is unaffected → Rx still syncs with Stream
```

---

## 8. Rx Type Inheritance Chain

**Scalars** (`Rx`, `RxBool`, etc.):

```dart
abstract class _RxImpl<T> extends RxInterface<T>
    with RxSubjectMixin<T>, ReactiveMixin<T>
```

**Collections** (`RxList`, `RxMap`, `RxSet`):

```dart
abstract class RxCollection<T>
    with RxSubjectMixin<T>, ReactiveMixin<T>
    implements RxInterface<T> {
  /* batch / readTracked / evaluateCondition */
}

class RxList<E> extends RxCollection<List<E>> with ListMixin<E> {}
```

| Module             | Responsibility                                                                                |
|--------------------|-----------------------------------------------------------------------------------------------|
| **RxSubjectMixin** | `subject`, broadcast, `close(subject)`                                                        |
| **ReactiveMixin**  | `value`, `bindStream`, `linkSubscription`, and `close` after canceling linked subscriptions   |
| **RxCollection**   | Collection batch `batchUpdating`, `refreshUnlessBatching`, `readTracked`, `evaluateCondition` |
| **ObxObserver**    | Proxy dependency table + sweep                                                                |

Collection writes go through `rawValue` / internal paths; reads use `readTracked` or
`ReactiveMixin.value` to avoid duplicate Obx dependency registration.

---

## 9. Signal Hot Path (1.0.1+)

- `add` / `addError` skip listener iteration when there are no subscribers (`value` is still
  updated).
- Single-subscriber fast path (`_forEachActive`).
- Notification path uses `try/finally` so a throwing listener does not leave the signal stuck in a
  busy state.
- `stream` getter caches the Stream adapter.

Signal can be used independently of Obx (event bus, manual `listen`).

---

## 10. Relationship Between Workers and Obx

Workers (`ever`, `debounce`, etc.) subscribe to the **subject** via `rx.listen()`, bypassing
`RxInterface.proxy`. Therefore:

- They do not trigger Obx-style dependency registration.
- They are not affected by Obx sweep.
- You must call `worker.dispose()` on page dispose, or use `RxLifecycleMixin`.

---

## 11. Lifecycle

| API                   | Behavior                                                                                   |
|-----------------------|--------------------------------------------------------------------------------------------|
| `Rx.close()`          | `ReactiveMixin` cancels linked subscriptions → `RxSubjectMixin` closes `subject`           |
| `ObxObserver.close()` | `_closed = true`; clears dependencies and listen callbacks                                 |
| `RxLifecycleMixin`    | Automatically `close`s registered Rx / subscriptions / Workers when the Widget is disposed |

---

## 12. 1.0.3 API Narrowing

- Removed the **`RxInterface.proxy` public setter**; production push uses the private *
  *`_buildWithProxy`**, and `notifyDependents` adds a `canUpdate` assertion on top of it.
- Public API keeps **`get proxy`** (read-only) and **`notifyDependents`** (for Obx).
- Tests use **`testDependents`** / **`resetProxy`** (`@visibleForTesting`, delegating to
  `_buildWithProxy`).

---

## 13. 1.0.2 Architecture Refactor Summary

| Old                               | New                                                              |
|-----------------------------------|------------------------------------------------------------------|
| `DependencySweepMixin` only sweep | **ObxObserver**: inline proxy dependency table + sweep           |
| Rx mixed `bindStream`             | Rx has no dependency table; **bindStream → linkSubscription**    |
| Obx managed its own subscriptions | **ObxObserver** exclusively owns the proxy dependency table      |
| `ObxDependencyHost`               | **`ObxObserver`** (directly connected to rebuild, no void relay) |
| `RxSubscriptionMixin`             | **`RxSubjectMixin`**                                             |
| Public `RxNotifier` typedef       | **`RxProxyContract`** sub-contract (same file as `RxInterface`)  |
| Repeated collection mixins        | **`RxCollection`** base class                                    |

---

## 14. Project Structure

```
lib/
├── ns_obx.dart
└── src/
    ├── rx/
    │   ├── core/          # RxInterface (includes RxProxyContract), RxSubjectMixin, ReactiveMixin
    │   └── types/         # Rx, RxCollection, RxList, RxMap, RxSet, primitives
    ├── signals/signal.dart
    ├── workers/workers.dart
    ├── lifecycle/         # RxLifecycleMixin, RxDisposable
    └── obx/               # Obx, ObxObserver, ObxValue
```

---

## 15. Further Reading

- [README.md](README.md) — Installation, API, examples
- [CHANGELOG.md](CHANGELOG.md) — Version history
- [example/](example/lib/main.dart) — Runnable demo (includes **Obx** Tab)
