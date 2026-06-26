# ns_obx Example

Demonstrates all core features of **ns_obx** 1.0.1.

## Running

```bash
cd example
flutter pub get
flutter run
```

## Testing

```bash
cd example
flutter test
```

## Pages

| Page | Features |
|------|----------|
| **Basic** | `.obs`, `Obx`, `peek`, `RxInt` operators, `RxString`, `RxBool`, `ObxValue` |
| **Collections** | `RxList` / `RxMap` / `RxSet` CRUD, `update` / `batchUpdate`, `addIf` + `RxCondition` |
| **Nullable** | `RxnInt`, nullable helpers, `peek`, `getOrElse`, `getOrThrow` |
| **Signal** | `Signal<T>` 独立事件通知（无需 Obx），listen / pause / resume / close |
| **AutoDispose** | `RxAutoDisposeMixin`, mount/unmount, `bindStream` |
| **Workers** | `ever`, `once`, `debounce`（trailing / `leading: true`）, `interval`, `worker()` |
| **Boundaries** | Obx read-only, conditional branches, stale 依赖, `select`, `update()` |

## Structure

```
example/
  lib/
    main.dart
    pages/
      basic_page.dart
      collection_page.dart
      nullable_page.dart
      signal_page.dart
      autodispose_page.dart
      workers_page.dart
      boundaries_page.dart
  test/
    widget_test.dart
```

## See also

- [Package README](../README.md) — API 速查与最佳实践
- [CHANGELOG](../CHANGELOG.md) — 版本变更
