# ns_obx 架构说明

本文档描述 ns_obx 内部依赖追踪与响应式数据流设计，面向维护者与需要深入理解 Obx / Rx 行为的进阶用户。API 用法见 [README.md](README.md)。

---

## 1. 设计目标

| 目标 | 做法 |
|------|------|
| GetX 兼容 | `.obs`、`Obx`、`RxList/Map/Set` 对外 API 保持一致 |
| 精确 rebuild | 字段级依赖；条件分支切换后 stale Rx 自动 detach |
| 订阅不混淆 | **proxy 依赖**（Obx 读 `.value`）与 **上游订阅**（`bindStream`、`select`）分表管理 |
| 低开销 | Signal 无订阅跳过通知；Obx 同帧合并 `setState`；增量 sweep 替代全量 `clearListeners` |

---

## 2. 分层总览

```
                    RxInterface（RxProxyContract + static proxy）
                              │
         ┌────────────────────┴────────────────────┐
         ▼                                         ▼
   Rx 发布侧                                   Obx 观察侧
   RxSubjectMixin                              ObxObserver
         │                                    （proxy 依赖表 + sweep）
         │                                         │
         └──────── subject / listen ◄──────── attach / rebuild
                              │
                    Signal（事件原语）
```

### 模块职责

| 模块 | 文件 | 职责 |
|------|------|------|
| **Signal** | `signals/signal.dart` | 同步事件广播；`value` 存储；无 buffer |
| **RxProxyContract** | `rx/core/rx_interface.dart` | 实例契约：依赖登记 + listen / close |
| **RxSubjectMixin** | `rx/core/rx_subject_mixin.dart` | 发布侧 `subject`、`listen()`（无 proxy 依赖表） |
| **ReactiveMixin** | `rx/core/reactive_mixin.dart` | `value`、`bindStream`、`linkSubscription` |
| **RxCollection** | `rx/types/rx_collection.dart` | 集合基类 + `RxCondition`；`readTracked` / `evaluateCondition` |
| **ObxObserver** | `obx/obx_observer.dart` | proxy 依赖表 + sweep + rebuild |
| **ObxState** | `obx/obx_widget.dart` | 持有 `ObxObserver`；sweep 包裹 builder；同帧 `scheduleFrameCallback` |

---

## 3. 两类订阅（核心区分）

### 3.1 Proxy 依赖（仅 ObxObserver）

当 `Obx` rebuild 执行 `count.value` 时：

1. `notifyDependents` 将 `RxInterface.proxy` 指向当前 `ObxObserver`（栈式压入/恢复，无 public setter）
2. Rx 的 getter 调用 `proxy.addListener(subject)`
3. `ObxObserver.addListener(signal)` → `_dispatch()`

**Rx 数据节点无 proxy 依赖表**，`addListener` / `clearListeners` 在 Rx 侧为无操作。

### 3.2 上游订阅（走 linkSubscription）

`bindStream`、`select` 对父 Rx 的 listen 等，通过 `ReactiveMixin.linkSubscription` 登记在 `_linkedSubscriptions`，**不进入** `_dependencies`。

原因：若混入同一张表，Obx 的 `endDependencySweep` 会误取消 `bindStream`，导致 Rx 不再同步外部 Stream。

```
bindStream(stream)  →  stream.listen(...)  →  linkSubscription(sub)
select(parent)      →  parent.listen(...)   →  linkSubscription(sub)
```

`close()` 时统一取消 linked 订阅与 proxy 依赖。

---

## 4. Rx 与 Obx 的职责分界

| | Rx（发布侧） | ObxObserver（观察侧） |
|---|-------------|----------------------|
| proxy 依赖表 | 无 | `_dependencies`（ObxObserver 内） |
| `canUpdate` | 恒 `false` | `_dependencies.isNotEmpty` |
| `addListener` | 无操作 | attach → rebuild |
| 值变化出口 | `subject` | `_dispatch()` |

---

## 5. Obx rebuild 与增量 sweep

`sweep` 由 **ObxObserver** 实现；Rx 数据节点不调用。

每个 `Obx` rebuild 流程（`ObxState.build`）：

```
beginDependencySweep()     // 快照当前 _dependencies 的 key 集合
  builder()                // 读 .value → retainDependency + 必要时 attach
endDependencySweep()       // 对快照中仍剩余的 key 执行 detach
```

与旧版每帧 `clearListeners()` 全量取消相比：

- 未变化的依赖 **保留** 原 `StreamSubscription`，避免重复 attach
- 条件分支切换后，不再读到的 Rx **自动** detach（stale 依赖修复）

业务代码通常无需调用上述 API；测试或手动重置可用 `clearListeners()`。

---

## 6. 同帧 rebuild 合并

同一帧内多个 Rx 连续 `subject.add` 时，`ObxObserver._dispatch` 通过 `SchedulerBinding.scheduleFrameCallback` 将多次通知合并为 **一次** `setState`。

典型场景：批量赋值 `loading` + `error`，或 `list.update` 后联动多个 Rx。

---

## 7. 典型数据流

### 7.1 用户改值 → Obx 更新

```
count.value++
  → ReactiveMixin setter → subject.add(newValue)
       ├─ ObxObserver（已 attach）→ scheduleFrameCallback → setState
       └─ rx.listen(subject)     → Worker / 副作用（不经依赖表）
```

### 7.2 Obx build 注册依赖

```
Obx builder 执行 count.value
  → getter 见 proxy != null → proxy.addListener(count.subject)
  → ObxObserver.addListener(count.subject) → rebuild
```

### 7.3 bindStream + Obx 同页

```
externalStream → bindStream → value setter → subject.add
                                    ↓
                              Obx 若正在读该 Rx → rebuild

Obx 条件分支不再读该 Rx → sweep 仅 detach Obx 侧 proxy
bindStream 的 linkSubscription 不受影响 → Rx 仍同步 Stream
```

---

## 8. Rx 类型继承链

**标量**（`Rx`、`RxBool` 等）：

```dart
abstract class _RxImpl<T> extends RxInterface<T>
    with RxSubjectMixin<T>, ReactiveMixin<T>
```

**集合**（`RxList`、`RxMap`、`RxSet`）：

```dart
abstract class RxCollection<T> with RxSubjectMixin<T>, ReactiveMixin<T>
    implements RxInterface<T> { /* batch / readTracked / evaluateCondition */ }

class RxList<E> extends RxCollection<List<E>> with ListMixin<E> { ... }
```

| 模块 | 职责 |
|------|------|
| **RxSubjectMixin** | `subject`、广播、`close(subject)` |
| **ReactiveMixin** | `value`、`bindStream`、`linkSubscription`、取消 linked 后 `close` |
| **RxCollection** | 集合批量 `batchUpdating`、`refreshUnlessBatching`、`readTracked`、`evaluateCondition` |
| **ObxObserver** | proxy 依赖表 + sweep |

集合写操作走 `rawValue` / 内部路径，读操作用 `readTracked` 或 `ReactiveMixin.value`，避免重复注册 Obx 依赖。

---

## 9. Signal 热路径（1.0.1+）

- 无订阅者时 `add` / `addError` 跳过 listener 遍历（仍更新 `value`）
- 单订阅 fast path（`_forEachActive`）
- 通知路径 `try/finally`，listener 抛错后不卡在 busy 状态
- `stream` getter 缓存 Stream 适配器

Signal 可脱离 Obx 单独使用（事件总线、手动 `listen`）。

---

## 10. Workers 与 Obx 的关系

Workers（`ever`、`debounce` 等）通过 `rx.listen()` 订阅 **subject**，不经过 `RxInterface.proxy`，因此：

- 不触发 Obx 式依赖注册
- 不受 Obx sweep 影响
- 需在页面 dispose 时 `worker.dispose()` 或配合 `ObxLifecycleMixin`

---

## 11. 生命周期

| API | 行为 |
|-----|------|
| `Rx.close()` | `ReactiveMixin` 取消 linked 订阅 → `RxSubjectMixin` 关闭 `subject` |
| `ObxObserver.close()` | `_closed = true`；清空依赖与 listen 回调 |
| `ObxLifecycleMixin` | Widget dispose 时自动 `close` 注册的 Rx / 订阅 / Worker |

---

## 12. 1.0.3 API 收窄

- 移除 **`RxInterface.proxy` public setter**；生产压栈走私有 **`_buildWithProxy`**，`notifyDependents` 在其上附加 `canUpdate` 断言
- 对外保留 **`get proxy`**（只读）、**`notifyDependents`**（Obx）
- 单测 **`testDependents`** / **`resetProxy`**（`@visibleForTesting`，委托 `_buildWithProxy`）

---

## 13. 1.0.2 架构整理摘要

| 旧 | 新 |
|----|-----|
| `DependencySweepMixin` 仅 sweep | **ObxObserver**：内联 proxy 依赖表 + sweep |
| Rx 混放 bindStream | Rx 无依赖表；**bindStream → linkSubscription** |
| Obx 自建 subscriptions | **ObxObserver** 独占 proxy 依赖表 |
| `ObxDependencyHost` | **`ObxObserver`**（直连 rebuild，无 void relay） |
| `RxSubscriptionMixin` | **`RxSubjectMixin`** |
| 公开 `RxNotifier` typedef | **`RxProxyContract`** 子契约（同文件于 `RxInterface`） |
| 集合 mixin 重复 | **`RxCollection`** 基类 |

---

## 14. 项目结构

```
lib/
├── ns_obx.dart
└── src/
    ├── rx/
    │   ├── core/          # RxInterface（含 RxProxyContract）, RxSubjectMixin, ReactiveMixin
    │   └── types/         # Rx, RxCollection, RxList, RxMap, RxSet, primitives
    ├── signals/signal.dart
    ├── workers/workers.dart
    └── obx/               # Obx, ObxObserver, ObxValue, ObxLifecycleMixin
```

---

## 15. 延伸阅读

- [README.md](README.md) — 安装、API、示例
- [CHANGELOG.md](CHANGELOG.md) — 版本变更
- [example/](../../example/) — 可运行 Demo（含 **Obx** Tab）
