[简体中文](CHANGELOG_CN.md)

# Changelog

All notable changes to this project will be documented in this file. This format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 1.0.6

### Changed

- Added DartDoc comments for all remaining public API members:
  `ObxObserver`, `RxNullable`, `RxCollection.refreshUnlessBatching`,
  `RxList` / `RxMap` / `RxSet` constructors, primitive reactive types
  (`RxBool`, `RxDouble`, `RxInt`, `RxString` and their nullable variants),
  `Signal` lifecycle callbacks, and `SignalSubscription`.
- Enabled the `public_member_api_docs` lint rule to maintain documentation coverage.

### Fixed

- Updated `.pubignore` so the `example/` directory is included in the published package.
- Escaped generic type references in DartDoc (`Stream<T>`, `Rx<T>`) to avoid HTML-interpretation
  lints.
- Compressed `CHANGELOG.md` and `CHANGELOG_CN.md`.
- Fixed broken code-block formatting in `BLOG_CN.md`.

## 1.0.5

### Changed

- Improved `pubspec.yaml` description format and added `topics` for pub.dev discoverability.
- Added a library-level dartdoc comment to `lib/ns_obx.dart`.
- Fixed broken code-block formatting in `README.md`, `README_CN.md`, and `BLOG_CN.md`.
- Added DartDoc comments to `Obx`, `ObxValue`, `ObxState`, and `ObxWidget.build`.

## 1.0.4

### Changed

- **Breaking**: `ObxLifecycleMixin` renamed to `RxLifecycleMixin`; file moved from
  `lib/src/obx/obx_lifecycle_mixin.dart` to `lib/src/lifecycle/rx_lifecycle_mixin.dart`.
- Updated naming and directory references across docs, examples, and tests.

## 1.0.3

### Changed

- **API narrowing**: removed the public setter of `RxInterface.proxy`; proxy writes now go through
  `notifyDependents`.
- Internal stack-pushing implementation renamed to `_buildWithProxy`.

No external behavior changes.

## 1.0.2

Dependency-tracking architecture cleanup.

### Changed

- **Breaking**: removed the public `RxNotifier<T>` typedef; `RxInterface` no longer exposes
  `beginDependencySweep` / `endDependencySweep`.
- **Breaking**: `Rx.addListener` no longer relays external Signals.
- **Breaking**: `RxAutoDisposeMixin` renamed to `ObxLifecycleMixin`; `lib/src/widgets/` moved to
  `lib/src/obx/`.
- Separated proxy dependencies from upstream subscriptions (`bindStream` / `select` go through
  `linkSubscription`).
- Obx now rebuilds directly through `ObxObserver`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full migration guide.

## 1.0.1

Performance and API refinement.

### Added

- `debounce(..., leading: true)`.
- `RxCondition` lazily-evaluated condition type.

### Changed

- **Breaking**: removed `SignalCondition`; use `RxCondition`.

## 1.0.0

First stable release. Refactored from the GetX reactive core while keeping API compatibility.

### Added

- Reactive variables, collections (`RxList` / `RxMap` / `RxSet`), `Obx`, `Workers`, and lifecycle
  helpers.
- `peek`, `select`, `bindStream`, batch updates, and collection snapshots.
- 301 unit / widget tests.
