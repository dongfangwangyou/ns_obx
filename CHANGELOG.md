[简体中文](CHANGELOG_CN.md)

# Changelog

All notable changes to this project will be documented in this file. This format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 1.0.5

### Changed

- Improved `pubspec.yaml` description format for better pub.dev compatibility.
- Added `topics` to `pubspec.yaml` to improve discoverability on pub.dev.
- Added a library-level dartdoc comment to `lib/ns_obx.dart`.
- Fixed broken code-block formatting in `README.md`, `README_CN.md`, and `BLOG_CN.md`.
- Added DartDoc comments to `Obx`, `ObxValue`, `ObxState`, and `ObxWidget.build` public API elements.

## 1.0.4

### Changed

- **Breaking**: `ObxLifecycleMixin` has been renamed to **`RxLifecycleMixin`**; the file moved from
  `lib/src/obx/obx_lifecycle_mixin.dart` to **`lib/src/lifecycle/rx_lifecycle_mixin.dart`**.
- Updated naming and directory references in `README.md`, `ARCHITECTURE.md`, `BLOG.md`, the example
  app, and test cases accordingly.

### Notes

`RxLifecycleMixin` more accurately conveys its responsibility for "Rx lifecycle management," and now
lives alongside `RxDisposable` in the `lifecycle/` directory, making it easier to discover and use.

## 1.0.3

### Changed

- **API narrowing**: Removed the public setter of `RxInterface.proxy` and the `_isNotifying` guard;
  proxy writes are now managed solely through the `notifyDependents` stack.
- Kept public **`get proxy`** and **`notifyDependents`**; the stack-pushing implementation is now *
  *`_buildWithProxy`** (private).
- Unit tests **`testDependents`** / **`resetProxy`** (`@visibleForTesting`, delegating to
  `_buildWithProxy`).

### Notes

No external behavior changes. If you previously assigned `RxInterface.proxy = ...` manually, use
Obx / `notifyDependents` instead.

## 1.0.2

Dependency-tracking architecture cleanup: unified the proxy dependency table and sweep, separated
upstream subscriptions for `bindStream` / `select`; Obx now rebuilds directly, removing the void
relay and the public `RxNotifier` type.

### Architecture

- **`RxProxyContract`**: instance contract in the same file as `RxInterface`; implemented by
  `RxSubjectMixin` and `ObxObserver`.
- **`RxCollection`**: collection base class in `types/rx_collection.dart` plus `RxCondition`;
  `readTracked` / `evaluateCondition` / `batchUpdating`.
- **`ReactiveMixin`**: `linkSubscription` moved from `RxSubjectMixin` (upstream subscriptions belong
  to the value-sync path).
- **ObxObserver**: inline proxy dependency table + sweep; Rx types no longer hold the dependency
  table.
- **Obx sweep**: incremental stale cleanup is now cohesive in `ObxObserver`; decoupled from
  `RxInterface`.
- **`RxSubjectMixin`**: Rx publisher-side `subject`, `listen()` (no proxy dependency table).
- **`ReactiveMixin`**: `value`, `bindStream`, `linkSubscription` (upstream subscriptions; not
  tracked by the proxy dependency table).
- **`ObxObserver`** (formerly `ObxDependencyHost`): UI observer that triggers rebuild directly after
  attach, without the void intermediary relay.
- **`bindStream` / `select`**: now go through `linkSubscription`, **do not enter** the proxy
  dependency table, preventing Obx sweep from accidentally canceling upstream subscriptions.

### Changed

- **Breaking**: Removed the public `RxNotifier<T>` typedef; `RxInterface` no longer declares
  `beginDependencySweep` / `endDependencySweep`.
- **Breaking**: `Rx.addListener` no longer relays external Signals; `canUpdate` is always `false` on
  Rx.
- **Breaking**: `RxAutoDisposeMixin` renamed to **`ObxLifecycleMixin`**; `lib/src/widgets/` moved to
  **`lib/src/obx/`**.

### Documentation

- Full layering, data-flow, and 1.0.2 migration guide in **[ARCHITECTURE.md](ARCHITECTURE.md)**; the
  repo **[example/](../../example/)** includes an **Obx** tab demonstrating collections, sweep, and
  bindStream.
- Sample app adds an **Obx** tab (`example/lib/pages/obx_page.dart`).

### Tests

- **317** unit / widget tests (covering `RxCollection`, `RxProxyContract`).

## 1.0.1

Performance and API refinement: Obx rebuild coalescing within the same frame, Signal hot-path
optimization, `debounce` leading mode, and `RxCondition` naming convergence.

### Added

- **`debounce(..., leading: true)`**: leading debounce—the first change inside the window is invoked
  immediately, subsequent changes are ignored until `time` of silence passes.
- **`RxCondition`**: lazily evaluated condition type (`bool Function()`), used by `RxList` /
  `RxMap` / `RxSet` for `addIf` / `addAllIf`.

### Improved

- **Obx**: When multiple Rx values change in the same frame,
  `SchedulerBinding.scheduleFrameCallback` now coalesces them into a single `setState`.
- **Signal**:
    - `add` / `addError` skip notification traversal when there are no subscribers (still updates
      `value`).
    - Single-subscriber fast path (`_forEachActive`).
    - Notification path wrapped in `try/finally`, so listeners throwing no longer leave the signal
      stuck in a busy state.
    - `stream` getter caches the Stream adapter to avoid repeated allocations.

### Changed

- **Breaking**: Removed the `SignalCondition` typedef; use `RxCondition` instead (exported from
  `package:ns_obx/ns_obx.dart`).

### Tests

- **306** unit / widget tests (added Obx same-frame coalescing, leading debounce, and Signal edge
  cases).

## 1.0.0

First stable release. Split from and refactored on top of the GetX reactive core, maintaining API
compatibility while fixing a number of historical issues and completing Obx dependency tracking,
collection write operations, batch updates, Workers, and lifecycle management.

### Core Capabilities

- Reactive variables: `Rx` / `RxBool` / `RxInt` / `RxDouble` / `RxString` and nullable variants.
- Reactive collections: `RxList` / `RxMap` / `RxSet`, supporting `.obs` extensions.
- UI components: `Obx`, `ObxValue`, `ObxWidget`.
- Lifecycle: `ObxLifecycleMixin` (`rx` / `subscription` / `listen` / `worker`).
- Workers: `ever`, `once`, `debounce`, `interval`.
- Utility APIs: `peek`, `select`, `bindStream`, `update` / `batchUpdate`, collection snapshots
  `toList` / `toMap` / `toSet`.
- Zero external dependencies, package size < 15 KB.

### New Features

- **Workers module**: lightweight side-effect API that returns disposable `Worker`s.
- **`ObxLifecycleMixin`**: page-level automatic disposal of Rx / subscriptions / Workers.
- **`peek`**: read the current value without registering an Obx dependency.
- **Collection snapshots**: `toList()` / `toMap()` / `toSet()` do not register dependencies.
- **`bindStream`**: returns a `StreamSubscription`, supports manual cancel; automatically canceled
  when the Rx is closed.
- **Batch updates**: `RxList.update`, `RxSet.update`, `RxMap.batchUpdate`; child operations inside
  the callback do not notify redundantly, and no notification is emitted if nothing changed.
- **`RxInterface` dependency-sweep API**: `beginDependencySweep` / `endDependencySweep` /
  `clearListeners`.
- **`select()` lifecycle**: derived Rx automatically cancels the parent Rx subscription via
  `linkSubscription` on `close()`.

### Bug Fixes from GetX-Obx

- **Obx stale dependencies**: after switching conditional branches, old Rx values no longer
  incorrectly trigger rebuilds; incremental dependency sweep replaces full `clearListeners`.
- **Signal concurrency safety**: proxy protection during notification, pending queue for
  subscription add/remove, runtime guards in release mode.
- **ObxWidget**: guards against `setState` after disposal.
- **Collection write-operation dependency leaks**: write methods uniformly go through `rawValue`,
  preventing accidental Obx dependency registration inside setters.
- **Duplicate / spurious collection notifications**:
    - `RxMap.addAll` / `RxSet.addAll` emit a single batch notification.
    - `operator+`, `assign` / `assignAll`, empty `clear`, empty `addAll`, same-value `[]=`, no-match
      `removeWhere` / `retainWhere`, already-sorted `sort`, same-length `length` setter, etc., skip
      `refresh` for no-ops.
    - `RxList` `ListMixin` write operations (`removeAt` / `insert` / `remove` / `removeRange`, etc.)
      emit a single notification.
    - `RxMap.removeWhere` / `update` / `updateAll`, `RxSet.removeWhere` emit a single notification.
    - `RxSet.update` suppresses duplicate child-operation notifications in batch mode.
- **`select()` subscription leak**: derived Rx closes and automatically cleans up the parent listen.
- **`Rx.fromStream`**: removed unsafe type cast, now returns `Rx<T?>`.
- **`ReactiveMixin.call`**: correctly assigns `null` when a nullable type is passed.
- **GetX historical issues**: thread safety, type safety (`Signal<T>` strongly typed `addListener`),
  API consistency, null safety.

### Improved

- **Obx dependency tracking**: `beginDependencySweep` / `endDependencySweep` incrementally remove
  stale dependencies while preserving unchanged subscriptions.
- **Collection read paths**: `containsKey` / `containsValue` (RxMap), `contains` / `lookup` /
  `iterator` / `length` (RxSet), `iterator` / `reversed` (RxList) register dependencies in a single
  `_readTracked` call.
- **`RxMap.putIfAbsent`**: override uses `rawValue`.
- **Extension naming unified**: `RxListExtension`, `RxMapExtension`, `RxSetExtension`, etc.
- **Field visibility**: internal fields such as `subject`, `subscriptions` are now `@protected`.
- **Public export cleanup**: `rx.dart` no longer exports internal mixins.
- **Docs and examples**: README covers usage boundaries, Obx dependency mechanism, collection batch
  updates; example Boundaries page.

### Tests

- **301** unit / widget tests covering Rx, Signal, Obx, collections, Workers, dependency sweep, and
  lifecycle.
