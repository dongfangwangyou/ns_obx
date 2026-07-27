/// 轻量级、高性能的 Flutter 响应式状态管理库。
///
/// ns_obx 从 GetX 响应式核心剥离重构，保留 `.obs` + `Obx` 用法，
/// 提供 Rx 响应式变量、集合类型、Workers、Signal 事件原语与生命周期管理工具。
///
/// 核心入口：
/// - `Rx` / `RxList` / `RxMap` / `RxSet`：响应式状态
/// - `Obx` / `ObxValue`：UI 依赖追踪与重建
/// - `RxLifecycleMixin` / `RxDisposable`：自动资源释放
/// - `ever` / `once` / `debounce` / `interval`：Rx 副作用
/// - `Signal`：轻量事件通知
library ns_obx;

export './src/lifecycle/rx_disposable.dart';
export './src/lifecycle/rx_lifecycle_mixin.dart';
export './src/obx/obx.dart';
export './src/rx/rx.dart';
export './src/signals/signal.dart';
export './src/workers/workers.dart';
