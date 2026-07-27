[English](CHANGELOG.md)

# Changelog

本文件记录 ns_obx 的版本变更。格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## 1.0.6

### 变更

- 为剩余所有公共 API 补充 DartDoc 注释，包括：
  `ObxObserver`、`RxNullable`、`RxCollection.refreshUnlessBatching`、
  `RxList` / `RxMap` / `RxSet` 构造器、基础响应式类型
  （`RxBool`、`RxDouble`、`RxInt`、`RxString` 及其可空变体）、
  `Signal` 生命周期回调与 `SignalSubscription`。
- 启用 `public_member_api_docs` lint 规则以保持文档覆盖率。

### 修复

- 调整 `.pubignore`，使 `example/` 目录能随包发布。
- 将 DartDoc 中的泛型引用（`Stream<T>`、`Rx<T>`）用反引号包裹，避免被解析为 HTML。
- 压缩 `CHANGELOG.md` 与 `CHANGELOG_CN.md` 体积。
- 修复 `BLOG_CN.md` 中的代码块换行格式错误。

## 1.0.5

### 变更

- 优化 `pubspec.yaml` 描述格式并新增 `topics` 标签。
- 为 `lib/ns_obx.dart` 新增库级 dartdoc 注释。
- 修复 `README.md`、`README_CN.md` 与 `BLOG_CN.md` 中代码块的格式错误。
- 为 `Obx`、`ObxValue`、`ObxState` 及 `ObxWidget.build` 补充 DartDoc 注释。

## 1.0.4

### 变更

- **破坏性**：`ObxLifecycleMixin` 更名为 `RxLifecycleMixin`；文件迁至
  `lib/src/lifecycle/rx_lifecycle_mixin.dart`。
- 同步更新文档、示例与测试用例中的命名与目录引用。

## 1.0.3

### 变更

- **API 收窄**：移除 `RxInterface.proxy` 的 public setter；proxy 写入改走 `notifyDependents`。
- 内部压栈实现重命名为 `_buildWithProxy`。

对外行为无变化。

## 1.0.2

依赖追踪架构整理。

### 变更

- **破坏性**：移除公开 `RxNotifier<T>` typedef；`RxInterface` 不再暴露 `beginDependencySweep` /
  `endDependencySweep`。
- **破坏性**：`Rx.addListener` 不再 relay 外部 Signal。
- **破坏性**：`RxAutoDisposeMixin` 更名为 `ObxLifecycleMixin`；`lib/src/widgets/` 迁至
  `lib/src/obx/`。
- proxy 依赖与上游订阅（`bindStream` / `select`）分表管理，后者改走 `linkSubscription`。
- Obx 通过 `ObxObserver` 直接触发 rebuild。

完整迁移说明见 [ARCHITECTURE.md](ARCHITECTURE.md)。

## 1.0.1

性能与 API 打磨版本。

### 新增

- `debounce(..., leading: true)`。
- `RxCondition` 延迟求值条件类型。

### 变更

- **破坏性**：移除 `SignalCondition`，请改用 `RxCondition`。

## 1.0.0

首个正式发布版本。从 GetX 响应式核心剥离重构，并保持 API 兼容。

### 新增

- 响应式变量、集合（`RxList` / `RxMap` / `RxSet`）、`Obx`、`Workers`、生命周期工具。
- `peek`、`select`、`bindStream`、批量更新、集合快照。
- 301 项单元 / Widget 测试。
