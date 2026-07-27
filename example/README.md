# ns_obx Example

A minimal, runnable Flutter app that demonstrates the core features of `ns_obx`.

## Run

```bash
cd example
flutter pub get
flutter run
```

## Structure

This example follows
the [Dart package layout conventions](https://dart.dev/tools/pub/package-layout#examples):

- `lib/main.dart` — Entry point of the example app.
- `lib/pages/` — Standalone demo pages, each focusing on one feature.
- `pubspec.yaml` — Depends on `ns_obx` via path import.
- `test/widget_test.dart` — Basic widget tests for the example app.

## Demo Pages

| Page         | Feature                                           |
|--------------|---------------------------------------------------|
| Basic Rx     | `.obs`, `Obx`, `ObxValue`, `peek`                 |
| Collections  | `RxList`, `RxMap`, `RxSet`, batch update          |
| Nullable     | `RxnInt`, `RxStringNullable`, null-safety helpers |
| Signal       | Event primitive, pause/resume/close               |
| EventChannel | Type-safe event bus built on `Signal`             |
| AutoDispose  | `RxLifecycleMixin` automatic resource cleanup     |
| Workers      | `ever`, `once`, `debounce`, `interval`            |
| Boundaries   | Best practices and common pitfalls                |

All pages use `package:ns_obx/ns_obx.dart` imports, matching how external apps consume the package.
