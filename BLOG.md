[简体中文](BLOG_CN.md)

# Flutter State Management, Lighter Still: From GetX's Reactive Core to ns_obx

> A technical note on why ns_obx was built, what problems it solves, and what it looks like today.  
> If you are already using GetX's `.obs` + `Obx`, this article may help you avoid a few pitfalls—or
> a few megabytes of dependencies.

---

## 1. What exactly are we optimizing?

Flutter state-management debates usually boil down to Provider vs Riverpod vs Bloc vs GetX. But look
at it from another angle:

**What does your app actually need?**

| Requirement level                            | Typical solution  | Cost                                        |
|----------------------------------------------|-------------------|---------------------------------------------|
| Global architecture, DI, compile-time safety | Riverpod          | Learning curve + size                       |
| Widget-level state passing                   | Provider          | Coarse granularity, easy whole-page rebuild |
| Field-level UI reactivity                    | GetX Obx / ns_obx | Must understand reactive boundaries         |
| Routing + i18n + full kitchen-sink           | GetX              | 200 KB+, heavy coupling                     |

Many projects only need the **first half** of the last row: **field-level UI reactivity**.  
Toggling a checkbox in a form should not rebuild the username field; changing a filter on a list
page should not rebuild the whole Scaffold.

That is the problem the **reactive primitive layer** is meant to solve—not by introducing yet
another routing or DI framework.

---

## 2. Why extract it from GetX?

GetX's reactive API (`.obs`, `Obx`, `RxList`) is pleasant to use, but as a "do-everything" framework
the reactive layer is tied to historical baggage:

- **Obx dependency tracking:** after a conditional branch switches, an old Rx may still trigger a
  rebuild (stale subscription).
- **Collection writes:** default `MapMixin` / `ListMixin` implementations can cause multiple
  notifications, or writes can accidentally register Obx dependencies.
- **Signal concurrency:** modifying the subscription list during notification can be unstable.
- **Types and API:** early `dynamic` listeners, inconsistent operator behavior, and so on.

If a project does **not** need GetX routing, DI, or internationalization, but imports the whole of
GetX just for `.obs`, it is effectively:

```
Carrying a 200 KB kitchen-sink for 15 KB of reactive capability.
```

So the positioning of **ns_obx** is very clear:

> Keep only the good parts of GetX's reactive layer, rewrite them in modern Dart, fix the known
> issues, keep the size under **15 KB**, and have **zero third-party dependencies**.

At the API level: change the `import` from `get` to `ns_obx`, and `.obs` / `Obx` usage stays largely
the same.

---

## 3. Architecture: three layers, each doing its own job

The internal structure of ns_obx can be summarized in a simple diagram:

```
Signal (event broadcast, can be used independently)
  └── Rx (reactive state; each Rx holds a Signal subject)
        ├── Obx (collect dependencies while building → Rx changes → local rebuild)
        └── Workers (listen to Rx changes for side effects, do not rebuild UI)
```

### Signal: the underestimated foundation

`Signal<T>` is a synchronous callback-based event dispatcher with no buffer, similar to a
stripped-down `StreamController`.  
**Rx is not a replacement for Signal; it is built on top of Signal**—each Rx's `subject` is a
Signal.

This means:

- Only want to fire events and not drive UI? Use **Signal** directly; no need to force Obx.
- Need "current value + UI update"? Use **Rx + Obx**.

Signal is not split into an independent pub package for now: it is small and tightly coupled with
the Rx kernel, so Flutter users get everything with one dependency; it is also reasonable to
`import ns_obx` and use only Signal for pure event scenarios.

### Rx + Obx: the core of field-level rebuilds

```dart
Column(
  children: [
    Obx(() => Text(user.value.name)), // only cares about name
    Obx(() => Text('${user.value.age}')), // only cares about age
  ],
)
```

When `name` changes, the second `Obx` does not rebuild—this is the core advantage over a Provider
`Consumer` that rebuilds the whole page.

### Workers: keep side effects out of the UI

Search debouncing, scroll throttling, one-time initialization—these do not belong inside `Obx`, and
you should not re-bind listeners on every rebuild.

```dart
// trailing: search only after input stops (default)
worker(debounce(query, _search, time: Duration(milliseconds: 300)));
// leading: immediate feedback on the first input
worker(debounce(query, _preview, leading: true, time: Duration(milliseconds: 300)));
worker(ever(count, (v) => log('count: $v')));
```

GetX users will find `ever` / `debounce` familiar; ns_obx also provides `once` and `interval`.
Starting with **1.0.1**, `debounce` supports `leading: true` and is wired into the lifecycle via
`RxLifecycleMixin.worker()`.

---

## 4. What "hard optimizations" did we make?

Below are the design decisions that **really** affect performance and correctness.

### 4.1 Obx: from full dependency clearing to incremental sweeping

**Problem:** Obx resubscribes on every rebuild. An Rx that was "not read" inside a conditional
branch may still trigger a rebuild after the branch switches.

**Approach:** `beginDependencySweep` / `endDependencySweep`

```
begin  →  snapshot the current subscription set
build  →  keep or create subscriptions for Rxs that are read
end    →  remove only stale dependencies that were not read this round
```

**Benefits:**

- After an `if/else` branch switch, the old Rx no longer triggers the UI by mistake.
- Unchanged dependencies keep their subscriptions, reducing cancel/re-create overhead.

This was the single most important item for both **correctness** and **performance** in 1.0.0.

### 4.2 Collections: write path, notification count, and batch APIs

Collections are where reactive UI most easily "silently drops frames":

| Problem                                                         | Handling                                                     |
|-----------------------------------------------------------------|--------------------------------------------------------------|
| `addAll` triggers refresh per key                               | Rewritten as a single batch notification                     |
| Same-value `[]=`, empty `clear`, no-match `removeWhere`         | Skip refresh as a no-op                                      |
| `ListMixin` methods like `removeAt` use default implementations | Override them with a single notification                     |
| Modifying a collection in a loop                                | `update` / `batchUpdate` merge changes into one notification |
| Writes accidentally registering Obx via the `value` getter      | Route through `rawValue` uniformly                           |
| Read paths like `containsKey` calling `[]` repeatedly           | `_readTracked` registers the dependency once                 |

```dart
list.update((items) {
  items.removeAt(0);
  items.add(99);
}); // notify only once

map.batchUpdate((m) {
  m.remove('old');
  m['new'] = 1;
});
```

For list pages, shopping carts, dynamic form fields, and similar scenes, this directly determines
whether Obx "jitters".

### 4.3 Lifecycle: page-level Rx should not leak

`RxLifecycleMixin` bundles the four common resource types in a page:

- `rx()` → Rx variables
- `subscription()` → Stream / bindStream
- `listen()` → Rx listeners
- `worker()` → Workers

They are released together when the page is disposed. Combined with `select()`, which automatically
cancels the parent Rx listen when a derived Rx is closed, this avoids derived-state leaks.

### 4.4 peek: distinguish "reading for UI" from "reading for side effects"

```dart
ever(count, (_) => log(count.peek)); // ✅ does not additionally subscribe to count

Obx(() => Text('${count.peek}')); // ❌ peek does not register a dependency; the UI will not update
```

The same applies to `toList()` / `toMap()` / `toSet()`—snapshot reads that do not pollute the Obx
dependency graph.

### 4.5 1.0.1: same-frame merging and Signal hot path

**Obx same-frame rebuild merging:** changing multiple Rxs in the same frame (e.g.
`loading.value = true; error.value = null`) could previously trigger multiple `setState` calls; now
they are merged into a single rebuild via `scheduleFrameCallback`.

**Signal optimization:** when there are no subscribers, listeners are not traversed; a single
subscriber takes a fast path; `try/finally` ensures listener exceptions do not leave Signal stuck in
a busy state.

**API convergence:** the condition type for collection `addIf` was renamed from `SignalCondition` to
**`RxCondition`**, placing the semantic ownership in the Rx module rather than Signal.

---

## 5. How to choose among mainstream solutions?

There is no silver bullet—only scenario fit.

### Choose ns_obx if you…

- Want **field-level rebuilds** without bringing in the GetX kitchen-sink
- Are **migrating from GetX** and hope to get by with just an import change
- Are building a **plugin / SDK** and are sensitive to dependency size (~15 KB)
- Already use **Riverpod / get_it** for DI and only need a good reactive layer
- Have page-centric state where a few `.obs` fields plus some `Obx` widgets are enough

### Do not choose ns_obx yet if you…

- Need **compile-time safety** and a complex dependency graph → Riverpod
- Need an integrated **routing + DI + theming** solution → GetX or a custom architecture
- Have team norms requiring **unidirectional data flow + explicit events** → Bloc

### Relationship with Provider / Riverpod

It is not a replacement; it is **complementary**:

```
Riverpod (DI + global state + compile-time checks)
    +
ns_obx (field-level Rx + Obx inside Controllers)
    =
Clean architecture + fine-grained UI updates
```

---

## 6. Getting started: a three-minute sanity check

**Install:**

```yaml
dependencies:
  ns_obx: ^1.0.5
```

**Minimal example:**

```dart
import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final count = 0.obs;
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Obx(() => Text('${count.value}'))),
        floatingActionButton: FloatingActionButton(
          onPressed: () => count.value++,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

**Migrating from GetX:** replace `import 'package:get/get.dart'` with
`import 'package:ns_obx/ns_obx.dart'`; most other code stays the same.

**Run the demo:**

```bash
cd example
flutter pub get
flutter run
```

The six tabs cover ns_bind, ns_store, ns_refresh, and the **ns_obx Obx Tab** (collections, sweep,
bindStream)—it is worth at least walking through the **Obx** tab.

---

## 7. Five rules when writing ns_obx

Practices distilled from 356 tests and the example edge pages:

1. **Inside Obx, only read `.value`; write in callbacks** — avoid calling `setState` during build
2. **Use `update()` to mutate object fields** — `user.value.name = 'x'` will not trigger the UI
3. **Use `RxLifecycleMixin` for page-level Rx** — do not rely on GC luck
4. **Use `update` / `batchUpdate` for multiple collection changes** — saving a few rebuilds once can
   mean saving hundreds on a list page
5. **Use Workers / `listen` / `peek` for side effects** — do not use Obx as a side-effect container

Collections are **container-level subscriptions**: reading `list[0]` subscribes to the whole list.
For item-level updates, split the Rx or split the Obx.

---

## 8. Current status: what did 1.0.1 bring?

**[ns_obx](https://pub.dev/packages/ns_obx)** current recommended version is **1.0.5**:

| Module    | Contents                                                                    |
|-----------|-----------------------------------------------------------------------------|
| Rx        | Basic types, nullable, `RxList/Map/Set`, `RxCondition`                      |
| UI        | Obx, ObxValue, incremental dependency sweep, **same-frame rebuild merging** |
| Lifecycle | RxLifecycleMixin                                                            |
| Workers   | ever / once / debounce (trailing + **leading**) / interval                  |
| Signal    | Standalone event primitive, **hot-path optimization**                       |
| Quality   | 356 tests, analyze clean                                                    |

**1.0.0** was the first official pub release (collection batch APIs, Workers, Obx stale-dependency
fixes, etc.); **1.0.1** focused on performance polish and API naming convergence. **1.0.4** introduced
`RxLifecycleMixin` and `RxDisposable`; **1.0.5** improved pub.dev metadata and documentation.

Docs: [README.md](README.md) · [CHANGELOG.md](CHANGELOG.md) · [example/](example/)

---

## 9. Closing: optimize state management by first optimizing granularity

Debates over state-management solutions often turn into arguments about whose architecture is more
complete.  
But for a large number of Flutter pages, the more practical optimization is:

**Make the UI rebuild only where necessary, keep side effects separate from the UI, and ensure
resources are actually released when the page is disposed.**

ns_obx does not do the all-in-one thing; it just does these three things extremely lightly and
well.  
If you agree that the reactive layer should be independent, testable, and migratable, it is worth a
try.

```yaml
dependencies:
  ns_obx: ^1.0.5
```

---

*MIT License · [Issues](https://pub.dev/packages/ns_obx) and PRs welcome*
