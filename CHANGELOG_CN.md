[English](CHANGELOG.md)

# Changelog

本文件记录 ns_obx 的版本变更。格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## 1.0.5

### 变更

- 优化 `pubspec.yaml` 描述格式，提升 pub.dev 兼容性。
- 为 `pubspec.yaml` 新增 `topics` 标签，提升 pub.dev 检索曝光。
- 为 `lib/ns_obx.dart` 新增库级 dartdoc 注释。
- 修复 `README.md`、`README_CN.md` 与 `BLOG_CN.md` 中代码块的格式错误。
- 为 `Obx`、`ObxValue`、`ObxState` 及 `ObxWidget.build` 等公共 API 补充 DartDoc 注释。

## 1.0.4

### 变更

- **破坏性**：`ObxLifecycleMixin` 更名为 **`RxLifecycleMixin`**；文件从
  `lib/src/obx/obx_lifecycle_mixin.dart` 迁至 **`lib/src/lifecycle/rx_lifecycle_mixin.dart`**
- 同步更新 `README.md`、`ARCHITECTURE.md`、`BLOG.md`、example 与测试用例中的命名与目录引用

### 说明

`RxLifecycleMixin` 更准确地表达「Rx 生命周期管理」的职责，且与新增的 `RxDisposable` 同属 `lifecycle/`
目录，便于用户发现与使用。

## 1.0.3

### 变更

- **API 收窄**：移除 `RxInterface.proxy` 的 public setter 及 `_isNotifying` 守卫；proxy 写入仅通过
  `notifyDependents` 栈式管理
- 保留 public **`get proxy`**、**`notifyDependents`**；压栈实现 **`_buildWithProxy`**（私有）
- 单测 **`testDependents`** / **`resetProxy`**（`@visibleForTesting`，委托 `_buildWithProxy`）

### 说明

对外行为无变化；若曾手动 `RxInterface.proxy = ...`，请改用 Obx / `notifyDependents`。

## 1.0.2

依赖追踪架构整理：统一 proxy 依赖表与 sweep，分离 `bindStream` / `select` 上游订阅；Obx 直连 rebuild，移除
void relay 与 `RxNotifier` 公开类型。

### 架构

- **`RxProxyContract`**：与 `RxInterface` 同文件的实例契约；`RxSubjectMixin` / `ObxObserver` 分别实现
- **`RxCollection`**：`types/rx_collection.dart` 集合基类 + `RxCondition`；`readTracked` /
  `evaluateCondition` / `batchUpdating`
- **`ReactiveMixin`**：`linkSubscription` 从 `RxSubjectMixin` 迁入（上游订阅属值同步路径）
- **ObxObserver**：内联 proxy 依赖表 + sweep；Rx 类型不再持有依赖表
- **Obx sweep**：增量 stale 清理内聚于 `ObxObserver`；从 `RxInterface` 抽离
- **`RxSubjectMixin`**：Rx 发布侧 `subject`、`listen()`（无 proxy 依赖表）
- **`ReactiveMixin`**：`value`、`bindStream`、`linkSubscription`（上游订阅，不进 proxy 依赖表）
- **`ObxObserver`**（原 `ObxDependencyHost`）：UI 观察者，attach 后直接触发 rebuild，不经 void 中转 relay
- **`bindStream` / `select`**：改走 `linkSubscription`，**不进入** proxy 依赖表，避免 Obx sweep 误取消上游订阅

### 变更

- **破坏性**：移除公开 `RxNotifier<T>` typedef；`RxInterface` 不再声明 `beginDependencySweep` /
  `endDependencySweep`
- **破坏性**：`Rx.addListener` 不再 relay 外部 Signal；Rx 上 `canUpdate` 恒为 `false`
- **破坏性**：`RxAutoDisposeMixin` 更名为 **`ObxLifecycleMixin`**；`lib/src/widgets/` 迁至 *
  *`lib/src/obx/`**

### 文档

- 完整分层、数据流与 1.0.2 迁移对照见 **[ARCHITECTURE.md](ARCHITECTURE.md)**；仓库 *
  *[example/](../../example/)** 含 **Obx** Tab 演示集合、sweep、bindStream

- 示例应用新增 **Obx** Tab（`example/lib/pages/obx_page.dart`）

### 测试

- **317** 项单元 / Widget 测试（含 `RxCollection`、`RxProxyContract`）

## 1.0.1

性能与 API 打磨版本：Obx 同帧 rebuild 合并、Signal 热路径优化、`debounce` leading 模式、`RxCondition`
命名收敛。

### 新增

- **`debounce(..., leading: true)`**：leading 防抖——窗口内首次变化立即调用，后续在静默 `time` 前忽略
- **`RxCondition`**：延迟求值条件类型（`bool Function()`），用于 `RxList` / `RxMap` / `RxSet` 的
  `addIf` / `addAllIf`

### 改进

- **Obx**：同帧内多个 Rx 连续变化时，通过 `SchedulerBinding.scheduleFrameCallback` 合并为一次
  `setState`
- **Signal**：
    - 无订阅者时 `add` / `addError` 跳过通知遍历（仍更新 `value`）
    - 单订阅 fast path（`_forEachActive`）
    - 通知路径 `try/finally`，listener 抛错后不卡在 busy 状态
    - `stream` getter 缓存 Stream 适配器，避免重复分配

### 变更

- **破坏性**：移除 `SignalCondition` typedef，请改用 `RxCondition`（自 `package:ns_obx/ns_obx.dart` 导出）

### 测试

- 306 项单元 / Widget 测试（新增 Obx 同帧合并、leading debounce、Signal 边界用例）

## 1.0.0

首个正式发布版本。从 GetX 响应式核心剥离并重构，在保持 API 兼容的前提下，修复多项历史遗留问题，补齐 Obx
依赖追踪、集合写操作、批量更新、Workers 与生命周期管理能力。

### 核心能力

- 响应式变量：`Rx` / `RxBool` / `RxInt` / `RxDouble` / `RxString` 及可空变体
- 响应式集合：`RxList` / `RxMap` / `RxSet`，支持 `.obs` 扩展
- UI 组件：`Obx`、`ObxValue`、`ObxWidget`
- 生命周期：`ObxLifecycleMixin`（`rx` / `subscription` / `listen` / `worker`）
- Workers：`ever`、`once`、`debounce`、`interval`
- 工具 API：`peek`、`select`、`bindStream`、`update` / `batchUpdate`、集合快照 `toList` / `toMap` /
  `toSet`
- 零外部依赖，打包体积 <15KB

### 新功能

- **Workers 模块**：轻量副作用 API，返回可 `dispose` 的 `Worker`
- **`ObxLifecycleMixin`**：页面级 Rx / 订阅 / Worker 自动释放
- **`peek`**：读取当前值不注册 Obx 依赖
- **集合快照**：`toList()` / `toMap()` / `toSet()` 不注册依赖
- **`bindStream`**：返回 `StreamSubscription`，支持手动 cancel；Rx `close` 时自动取消
- **批量更新**：`RxList.update`、`RxSet.update`、`RxMap.batchUpdate`；回调内子操作不重复通知，无变化不通知
- **`RxInterface` 依赖扫描 API**：`beginDependencySweep` / `endDependencySweep` / `clearListeners`
- **`select()` 生命周期**：派生 Rx `close()` 时通过 `linkSubscription` 自动取消父 Rx 订阅

### 修复Gex-Obx中Bug

- **Obx stale 依赖**：条件分支切换后，旧 Rx 不再错误触发 rebuild；采用增量依赖扫描替代全量
  `clearListeners`
- **Signal 并发安全**：通知期间代理保护、订阅增删待处理队列、Release 模式运行时守卫
- **ObxWidget**：dispose 后 `setState` 异常保护
- **集合写操作依赖误注册**：写方法统一走 `rawValue`，避免 setter 中意外注册 Obx 依赖
- **集合重复 / 无效通知**：
    - `RxMap.addAll` / `RxSet.addAll` 批量单次通知
    - `operator+`、`assign` / `assignAll`、空 `clear`、空 `addAll`、同值 `[]=`、无匹配 `removeWhere` /
      `retainWhere`、已排序 `sort`、同长度 `length` setter 等 no-op 跳过 `refresh`
    - `RxList` ListMixin 写操作（`removeAt` / `insert` / `remove` / `removeRange` 等）单次通知
    - `RxMap.removeWhere` / `update` / `updateAll`、`RxSet.removeWhere` 单次通知
    - `RxSet.update` 批量模式内抑制子操作重复通知
- **`select()` 订阅泄漏**：派生 Rx 关闭时自动清理父级 listen
- **`Rx.fromStream`**：移除不安全类型转换，返回 `Rx<T?>`
- **`ReactiveMixin.call`**：可空类型传入 `null` 时正确赋值
- **GetX 历史问题**：线程安全、类型安全（`Signal<T>` 强类型 `addListener`）、API 一致性、空安全

### 改进

- **Obx 依赖追踪**：`beginDependencySweep` / `endDependencySweep` 增量移除 stale 依赖，保留未变订阅
- **集合读路径**：`containsKey` / `containsValue`（RxMap）、`contains` / `lookup` / `iterator` /
  `length`（RxSet）、`iterator` / `reversed`（RxList）经 `_readTracked` 单次注册依赖
- **`RxMap.putIfAbsent`**：override 走 `rawValue`
- **Extension 命名统一**：`RxListExtension`、`RxMapExtension`、`RxSetExtension` 等
- **字段可见性**：`subject`、`subscriptions` 等内部字段 `@protected`
- **公开导出收敛**：`rx.dart` 不再导出内部 mixin
- **文档与示例**：README 使用边界、Obx 依赖机制、集合批量更新；example Boundaries 页

### 测试

- 301 项单元 / Widget 测试覆盖 Rx、Signal、Obx、集合、Workers、依赖扫描与生命周期
