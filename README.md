[简体中文](README_CN.md)

# ns_obx

[![pub version](https://img.shields.io/pub/v/ns_obx)](https://pub.dev/packages/ns_obx)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A **lightweight**, **high-performance**, **reactive** state management library for Flutter.
Refactored from the GetX reactive core, it keeps the `.obs` + `Obx` API, fixes several historical
issues, has zero third-party dependencies, and a bundle size of **<15KB**.

> It only does "Rx variables + Obx widget + lifecycle utilities"; no routing / DI /
> internationalization. If you've used the GetX reactive layer, migration is almost effortless.

---

## Features

|                              |                                                                                                 |
|------------------------------|-------------------------------------------------------------------------------------------------|
| **Tiny size**                | <15KB after bundling                                                                            |
| **Zero deps**                | Only depends on the Flutter SDK                                                                 |
| **Type-safe**                | Full generics and compile-time type checking                                                    |
| **High performance**         | Field-level rebuilds; multiple Rx changes in the same frame are merged into a single `setState` |
| **GetX-compatible**          | Same `.obs`, `Obx`, `RxList/Map/Set` APIs                                                       |
| **Workers**                  | `ever` / `once` / `debounce` (leading/trailing) / `interval`                                    |
| **Signal**                   | Built-in lightweight event primitive; usable without Obx                                        |
| **Lifecycle**                | `RxLifecycleMixin` automatically disposes Rx / subscriptions / Workers                          |
| **Collection optimizations** | Batch `update` / `batchUpdate`, no-op skips invalid notifications                               |

---

## Requirements

|          | Version          |
|----------|------------------|
| Dart SDK | `>=3.4.0 <4.0.0` |
| Flutter  | `>=3.13.0`       |

---

## Installation

```yaml
dependencies:
  ns_obx: ^1.0.5
```

```bash
flutter pub get
```

---

## Quick Start

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
        appBar: AppBar(title: const Text('ns_obx Demo')),
        body: Center(
          child: Obx(() => Text('Count: ${count.value}', style: const TextStyle(fontSize: 32))),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => count.value++,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

**Key point:** inside the `Obx` builder, **only read** `.value`; mutate values inside callbacks such
as `onPressed`.

---

## Table of Contents

- [Exports](#exports)
- [Core Modules](#core-modules)
- [API Cheatsheet](#api-cheatsheet)
- [Page-level Lifecycle](#page-level-lifecycle-rxlifecyclemixin)
- [Migrating from GetX](#migrating-from-getx)
- [Comparison](#comparison)
- [Best Practices](#best-practices)
- [Example Apps](#example-apps)
- [Advanced: Obx Dependency Tracking and Rebuild](#advanced-obx-dependency-tracking-and-rebuild)
- [Changelog](#changelog)

---

## Exports

`import 'package:ns_obx/ns_obx.dart';` includes:

| Module      | Main contents                                                                                                   |
|-------------|-----------------------------------------------------------------------------------------------------------------|
| **Rx**      | `Rx<T>`, `RxBool/Int/Double/String`, nullable variants, `RxCollection`, `RxList/Map/Set`, `.obs`, `RxCondition` |
| **Obx**     | `Obx`, `ObxValue`, `ObxWidget`, `RxLifecycleMixin`                                                              |
| **Workers** | `ever`, `once`, `debounce`, `interval`, `Worker`                                                                |
| **Signal**  | `Signal<T>`, `SignalSubscription` (event notifications, no Obx required)                                        |

---

## Core Modules

```
Signal (event broadcast, optionally standalone)
  └── Rx (reactive state + subject)
        ├── RxCollection → RxList / RxMap / RxSet
        ├── Obx (UI dependency tracking + rebuild)
        └── Workers (Rx side effects: debounce / throttle / listen)
```

| Need                                          | Choose                    |
|-----------------------------------------------|---------------------------|
| UI reacts to data                             | **Rx + Obx**              |
| Debounced search, logging, one-shot callbacks | **Workers** or `listen()` |
| Pure events, not driving UI                   | **Signal**                |
| Auto-cleanup when page is destroyed           | **RxLifecycleMixin**      |

---

## API Cheatsheet

### Reactive Variables

```dart
final count = 0.obs; // RxInt
final name = 'hello'.obs; // RxString
final flag = true.obs; // RxBool
final user = Rx<User>(User()); // Rx<T>

final n = RxnInt(); // Rx<int?>, initially null
final list = <int>[1, 2].obs; // RxList
final map = {'a': 1}.obs; // RxMap
final set = {1, 2}.obs; // RxSet
```

Nullable type extensions (`RxNullable` / `RxnInt` etc.): `isNull`, `let`, `ifNull`, `getOrElse`,
`getOrThrow`.

```dart
final title = RxStringNullable();
title.getOrElse('Untitled');
title.let((v) => print(v.length));
```

### Obx / ObxValue

```dart
// Read-only display
Obx(() => Text('${count.value}'));

// Multiple Rx mutated in the same frame: Obx rebuilds only once
void onSubmit() {
  loading.value = true;
  error.value = null;
  // Two assignments → one setState
}

// Locally bound Rx widget
ObxValue<RxBool>(
  (data) => Switch(value: data.value, onChanged: (v) => data.value = v),
  false.obs,
);
```

### Read/Write and Utilities

```dart
count.value = 1; // write (notifies subscribers)
count.value++; // read + write
print(count.peek); // read current value without registering an Obx dependency

user.update((u) => u.name = 'Bob'); // mutate internal object fields
final nameRx = user.select((u) => u.name); // derived Rx (must manage close)
count.bindStream(stream); // returns StreamSubscription
list.toList(); map.toMap(); set.toSet(); // snapshots, do not register dependencies
```

### Collection Batch Updates

| Type     | API               | Description                                                     |
|----------|-------------------|-----------------------------------------------------------------|
| `RxList` | `update(fn)`      | Multiple mutations inside callback merged into one notification |
| `RxMap`  | `batchUpdate(fn)` | Same as above (avoids collision with `Map.update`)              |
| `RxSet`  | `update(fn)`      | Callback receives `Set<E>`                                      |

```dart
list.update((items) {
  items.add(3);
  items.removeWhere((e) => e.isOdd);
});

map.batchUpdate((m) {
  m.remove('old');
  m['new'] = 1;
});
```

Collections also support `assign` / `assignAll`, `addIf` / `addAllIf`; write operations skip invalid
`refresh` when the content hasn't changed.

`addIf` / `addAllIf` accept `condition` as either `bool` or a lazily evaluated `RxCondition` (
`bool Function()`):

```dart
list.addIf(() => user.value.isAdmin, item);
list.addAllIf(true, [1, 2, 3]);
```

### Signal (Standalone Event Notifications)

No Obx required; suitable for in-module pub-sub, lifecycle hooks, etc.:

```dart
final events = Signal<String>();
final sub = events.listen((msg) => print(msg));
events.emit('hello');
await sub.cancel();
events.close();
```

| API                           | Description                        |
|-------------------------------|------------------------------------|
| `listen` / `emit`             | Subscribe and emit                 |
| `pause` / `resume` / `cancel` | Subscription control               |
| `close`                       | Close; `value` keeps the last item |
| `stream`                      | Adapts to `Stream<T>`              |

> Signal is a hot event source that does not replay to new subscribers; when there are no
> subscribers, `emit` only updates `value` and does not iterate listeners. Use Rx when you need "
> current value + UI updates".

#### Using Signal to Implement a Type-Safe EventChannel

Signal's non-replay behavior makes it ideal for one-shot event buses. Here is a zero-dependency,
fully type-safe `EventChannel<T>`:

```dart
class EventChannel<T> {
  final Signal<T> _signal = Signal<T>();

  /// Emit an event
  void emit(T event) => _signal.emit(event);

  /// Subscribe to events
  SignalSubscription<T> on(void Function(T event) handler) =>
      _signal.listen(handler);

  /// Close the channel
  void close() => _signal.close();
}
```

Usage example:

```dart
// 1. Define business event channels
class AuthEvents {
  AuthEvents._();

  static final logout = EventChannel<LogoutEvent>();
  static final sessionExpired = EventChannel<SessionExpiredEvent>();
}

// 2. Subscribe (usually in initState / route listeners)
late final SignalSubscription<LogoutEvent> _sub;

@override
void initState() {
  super.initState();
  _sub = AuthEvents.logout.on((event) {
    Navigator.of(context).pushReplacementNamed('/login');
  });
}

@override
void dispose() {
  _sub.cancel();
  super.dispose();
}

// 3. Emit events (from anywhere)
AuthEvents.logout.emit(LogoutEvent());
```

> Why not Rx? Rx replays the current value to new subscribers, which can easily lead to duplicate
> event consumption; Signal only notifies subscribers of events that occur after subscription, making
> it more suitable for "command / side-effect" style communication.

### Workers

```dart
class _PageState extends State<Page> with RxLifecycleMixin {
  late final query = rx(''.obs);

  @override
  void initState() {
    super.initState();
    // Trailing debounce: search 300ms after typing stops (default)
    worker(debounce(query, _search, time: const Duration(milliseconds: 300)));
    // Leading debounce: search immediately on first input, ignore subsequent within window
    worker(debounce(query, _preview, leading: true, time: const Duration(milliseconds: 300)));
    worker(ever(count, (v) => print(v)));
    worker(once(count, (_) => _initOnce()));
  }
}
```

| API        | Behavior                                                                                                                                  |
|------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `ever`     | Called on every change (not including the initial value)                                                                                  |
| `once`     | Auto-cancels after the first change                                                                                                       |
| `debounce` | Default **trailing**: calls the latest value after `time` of silence; `leading: true` for **leading** (first in window fires immediately) |
| `interval` | At most once per `time` (throttle; first in window fires immediately)                                                                     |

---

## Page-level Lifecycle (RxLifecycleMixin)

```dart
class _PageState extends State<Page> with RxLifecycleMixin {
  late final count = rx(0.obs);

  @override
  void initState() {
    super.initState();
    listen(count, (v) => debugPrint('$v'));
    subscription(count.bindStream(myStream));
    worker(debounce(query, _search));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${count.value}'));
  }
  // On dispose, automatically closes Rx, cancels subscriptions, and disposes Workers
}
```

| Method              | Purpose                                         |
|---------------------|-------------------------------------------------|
| `rx(reactive)`      | Register an Rx to `close` on dispose            |
| `subscription(sub)` | Register a `StreamSubscription`                 |
| `listen(rx, fn)`    | Listen to an Rx and auto-track the subscription |
| `worker(w)`         | Register a Worker                               |

---

## Migrating from GetX

```dart
// import 'package:get/get.dart';
import 'package:ns_obx/ns_obx.dart';

final count = 0.obs;
Obx(() => Text('${count.value}'));
```

Main difference: ns_obx **does not include** `GetMaterialApp`, routing, or `Get.put`; choose your
own DI solution or pair with an ecosystem DI package.

---

## Comparison

|                        |               ns_obx               | Provider / Riverpod |    GetX     |
|------------------------|:----------------------------------:|:-------------------:|:-----------:|
| Size                   |               ~15KB                |        50KB+        |   200KB+    |
| Reactivity granularity |          **Field-level**           |    Widget-level     | Field-level |
| DI / Routing           |                 ❌                  |     ✅ / partial     |      ✅      |
| Learning curve         | Minimal (zero cost for GetX users) |     Low~medium      |   Medium    |

```dart
// Provider: changing name rebuilds the whole Consumer
// ns_obx: each Obx only depends on the Rx it reads
Obx(() => Text(user.value.name)); // only this line rebuilds
Obx(() => Text('${user.value.age}')); // rebuilds only when age changes
```

**Good for:** local state, GetX migration, plugins/SDKs, combining with DI solutions like
Riverpod.  
**Not for:** large architectures that need built-in DI/routing/compile-time safety (choose Riverpod,
etc.).

---

## Best Practices

| ✅ Recommended                                                  | ❌ Avoid                                                            |
|----------------------------------------------------------------|--------------------------------------------------------------------|
| Only **read** `.value` inside the Obx builder                  | Writing `count.value++` inside the builder                         |
| Mutate values inside `onPressed` / Controller                  | Reading `.value` inside async callbacks expecting Obx subscription |
| Use `update()` for object field changes                        | `user.value.name = 'x'` (reference unchanged, no trigger)          |
| Use `RxLifecycleMixin` for page-level Rx                       | Using an Rx after `close()` inside Obx                             |
| Use `peek` / Workers / `listen` for side effects               | Using `peek` inside Obx expecting rebuild                          |
| Use `update` / `batchUpdate` for multiple collection mutations | Modifying collections in a loop triggering multiple rebuilds       |
| `select()` derived Rx should `close` with the page             | Leaking derived Rx without disposal                                |

**Collection granularity:** reading `list[0]` or `map['k']` subscribes to the **whole container**;
for fine-grained single-item updates, split into multiple Rx variables or multiple Obx widgets.

**Conditional branches:** when `if/else` branches switch inside Obx, stale Rx dependencies from the
old branch are automatically removed (incremental dependency sweep).

See the **[example/](../../example/)** directory in the repo, especially the **Obx** tab (
collections, `RxCondition`, conditional branch sweep, `bindStream`) for more details.

---

## Common Pitfalls

### 1. Writing `.value` inside the `Obx` builder

```dart
// ❌ Wrong: won't trigger rebuild, and may trigger an assertion
Obx(() {
  count.value++;
  return Text('${count.value}');
});

// ✅ Correct: only read inside the builder
Obx(() => Text('${count.value}'));
```

### 2. Reading `.value` in async callbacks expecting Obx subscription

```dart
// ❌ Wrong: Future callback is not in the Obx build call stack
Obx(() => FutureBuilder(
  future: fetch(user.value.id), // will not subscribe to user
  builder: ...,
));

// ✅ Correct: read directly inside Obx
Obx(() => Text('${user.value.name}'));
```

### 3. Mutating internal object fields doesn't trigger updates

```dart
// ❌ Wrong: reference unchanged
user.value.name = 'Bob';

// ✅ Correct: triggers setter / refresh
user.update((u) => u.name = 'Bob');
```

### 4. Derived Rx leaks

```dart
// ❌ Wrong: derived won't be released with the page
final derived = user.select((u) => u.name);

// ✅ Correct: register with RxLifecycleMixin / RxDisposable
final derived = rx(user.select((u) => u.name));
// Or for non-Widget scopes:
final disposable = RxDisposable();
final derived = disposable.rx(user.select((u) => u.name));
```

### 5. Reading a collection item subscribes to the whole container

```dart
// Subscribes to the whole list; any element change rebuilds
Obx(() => Text('${list[0]}'));

// ✅ For fine-grained single-item updates, split into independent Rx
final firstItem = 0.obs;
Obx(() => Text('${firstItem.value}'));
```

### 6. Using an Rx in Obx after `close()`

```dart
// ❌ Wrong: Obx will read an invalid state after count is closed
count.close();
return Obx(() => Text('${count.value}'));

// ✅ Correct: let the lifecycle mixin close everything on dispose
class _PageState extends State<Page> with RxLifecycleMixin { ... }
```

---

## Example Apps

### Minimal Example (Recommended for Getting Started)

The **[example/](./example/)** directory inside the package provides a minimal runnable app that
only depends on `ns_obx`:

```bash
cd dependence/ns_obx/example
flutter pub get
flutter run
```

Includes **Counter** (`.obs` + `Obx`) and **Search** (`debounce` + `RxLifecycleMixin`) pages.

### Full Integrated Demo

The repo root **[example/](../../example/)** is a multi-package integrated demo (`ns_obx` /
`ns_bind` / `ns_store` /
`ns_refresh`):

```bash
cd example
flutter pub get
flutter run
```

| Tab       | Content shown                                                                                                             |
|-----------|---------------------------------------------------------------------------------------------------------------------------|
| Counter   | `Obx`, `.obs`, multi-type Rx, `RxList` history (via ns_bind)                                                              |
| Users     | List and form reactivity (via ns_bind)                                                                                    |
| BindScope | Scoping and lifecycle (via ns_bind)                                                                                       |
| Store     | Pagination store (via ns_store)                                                                                           |
| Refresh   | Pull-to-refresh pagination (via ns_refresh)                                                                               |
| **Obx**   | **ns_obx specific**: collection `update`/`addIf`, `RxCondition`, conditional branch sweep, `bindStream`, same-frame merge |

---

## Advanced: Obx Dependency Tracking

- **Incremental sweep:** `ObxObserver.begin/endDependencySweep` removes stale dependencies
- **Two subscription types:** Obx reading `.value` / `readTracked` goes through proxy;
  `bindStream` / `select` goes through `ReactiveMixin.linkSubscription`
- **Same-frame merge:** multiple Rx changes in the same frame are merged into a single `setState`

For the full layering, data flow, and 1.0.2 architecture notes, see **[ARCHITECTURE.md](ARCHITECTURE.md)**.

---

## Project Structure

```
lib/
├── ns_obx.dart              # Unified exports
└── src/
    ├── rx/                  # RxInterface, RxCollection, RxSubjectMixin, ReactiveMixin
    ├── signals/signal.dart  # Signal event primitive
    ├── workers/workers.dart # Workers side effects
    ├── lifecycle/           # RxLifecycleMixin, RxDisposable
    └── obx/                 # Obx, ObxObserver, ObxValue
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

**1.0.2** — `RxProxyContract`, `RxCollection` base class, inline proxy dependency table in
`ObxObserver`, `linkSubscription` moved into `ReactiveMixin`.

**1.0.1** — Obx same-frame rebuild merge, Signal hot-path optimization, `debounce(leading: true)`,
`RxCondition`.

**1.0.0** — First stable release: Obx incremental dependency scan, collection write operations and
batch APIs, Workers, `peek`.

---

## License

[MIT License](LICENSE)

Issues and Pull Requests are welcome.
