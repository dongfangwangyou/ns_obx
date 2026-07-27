[English](BLOG.md)

# Flutter 状态管理还能更轻：从 GetX 响应式内核到 ns_obx

> 一篇关于「为什么做 ns_obx、解决了什么问题、现在长什么样」的技术笔记。  
> 如果你已经在用 GetX 的 `.obs` + `Obx`，这篇文章可能帮你少踩几个坑，或者少背几 MB 的包。

---

## 1. 我们到底在优化什么？

Flutter 状态管理的争论往往落在 Provider vs Riverpod vs Bloc vs GetX 上。但换一个角度问：

**你的 App 真正需要的是什么？**

| 需求层次           | 典型方案              | 代价                |
|----------------|-------------------|-------------------|
| 全局架构、DI、编译时安全  | Riverpod          | 学习曲线 + 体积         |
| Widget 级状态传递   | Provider          | 粒度较粗，容易整页 rebuild |
| 字段级 UI 响应      | GetX Obx / ns_obx | 需理解响应式边界          |
| 路由 + 国际化 + 全家桶 | GetX              | 200KB+，耦合重        |

很多项目其实只需要最后一列里的**前半句**：**字段级 UI 响应**。  
表单里改勾选框不应重建用户名输入框；列表页改筛选条件不应重建整个 Scaffold。

这就是 **响应式原语层** 要解决的问题——而不是再引入一套路由或 DI 框架。

---

## 2. 为什么从 GetX 里「拆」出来？

GetX 的响应式 API（`.obs`、`Obx`、`RxList`）用起来很顺手，但作为一个「大而全」框架，响应式层和历史包袱绑在一起：

- **Obx 依赖追踪**：条件分支切换后，旧 Rx 可能仍触发 rebuild（stale 订阅）
- **集合写操作**：`MapMixin` / `ListMixin` 默认实现可能导致多次通知，或写操作误注册 Obx 依赖
- **Signal 并发**：通知过程中改订阅列表可能不稳定
- **类型与 API**：早期 `dynamic` 监听、运算符行为不一致等问题

如果项目**不需要** GetX 的路由、DI、国际化，却为了 `.obs` 引入整个 GetX，相当于：

```
为了 15KB 的响应式能力，背上了 200KB 的全家桶。
```

**ns_obx 的定位**因此非常明确：

> 只保留 GetX 响应式层里好用的部分，用现代 Dart 重写，修掉已知问题，体积控制在 **15KB 以内**，**零第三方依赖
**。

API 层面：`import` 从 `get` 换成 `ns_obx`，`.obs` 和 `Obx` 写法基本不变。

---

## 3. 架构：三层，各干各的

ns_obx 的内部结构可以用一张简图概括：

```
Signal（事件广播，可选独立使用）
  └── Rx（响应式状态，每个 Rx 持有一个 Signal subject）
        ├── Obx（build 时收集依赖 → Rx 变 → 局部 rebuild）
        └── Workers（监听 Rx 变化，做副作用，不 rebuild UI）
```

### Signal：被低估的底座

`Signal<T>` 是同步回调式的事件分发，无 buffer，类似精简版 `StreamController`。  
**Rx 不是 Signal 的替代品，而是建立在 Signal 之上**——每个 Rx 的 `subject` 就是一个 Signal。

这意味着：

- 只想发事件、不驱动 UI？直接用 **Signal**，不必强行套 Obx
- 需要「当前值 + UI 更新」？用 **Rx + Obx**

Signal 暂不拆独立 pub 包：体量小、与 Rx 内核一体，Flutter 用户一个依赖即可；纯事件场景 `import ns_obx`
只用 Signal 也完全合理。

### Rx + Obx：字段级 rebuild 的核心

```dart
Column(
  children: [
    Obx(() => Text(user.value.name)), // 只关心 name
    Obx(() => Text('${user.value.age}')), // 只关心 age
  ],
)
```

`name` 变化时，第二个 `Obx` 不会重建——这是相对 Provider `Consumer` 整页 rebuild 的核心优势。

### Workers：把副作用从 UI 里拿出来

搜索防抖、滚动节流、一次性初始化——这些不该写在 `Obx` 里，也不该每次 rebuild 都重新绑监听。

```dart
// 尾随：停止输入后再搜索（默认）
worker(debounce(query, _search, time: Duration(milliseconds: 300)));
// leading：首次输入立即反馈
worker(debounce(query, _preview, leading: true, time: Duration(milliseconds: 300)));
worker(ever(count, (v) => log('count: $v')));
```

GetX 用户会对 `ever` / `debounce` 感到熟悉；ns_obx 提供 `once`、`interval`，**1.0.1** 起 `debounce` 支持
`leading: true`，并与 `RxLifecycleMixin.worker()` 打通生命周期。

---

## 4. 我们做了哪些「硬优化」？

下面是**对性能与正确性真正有影响**的设计决策。

### 4.1 Obx：从全量清依赖到增量扫描

**问题：** Obx 每次 rebuild 都会重新订阅，条件分支里「没读到的 Rx」可能在切换后仍触发 rebuild。

**做法：** `beginDependencySweep` / `endDependencySweep`

```
begin  →  快照当前订阅集合
build  →  读到的 Rx 保留或新建订阅
end    →  仅移除「本轮未读到」的 stale 依赖
```

**收益：**

- 条件 `if/else` 切换分支后，旧 Rx 不再误触发 UI
- 未变依赖保留订阅，减少 cancel/重建开销

这是 1.0.0 里对 **正确性** 和 **性能** 都最关键的一项。

### 4.2 集合：写路径、通知次数、批量 API

集合是响应式 UI 里最容易「 silently 刷帧」的地方：

| 问题                                   | 处理                               |
|--------------------------------------|----------------------------------|
| `addAll` 逐键触发多次 refresh              | 重写为批量单次通知                        |
| 同值 `[]=`、空 `clear`、无匹配 `removeWhere` | no-op 跳过 refresh                 |
| ListMixin 的 `removeAt` 等走默认实现        | override，单次通知                    |
| 循环改集合                                | `update` / `batchUpdate` 合并为一次通知 |
| 写操作经 `value` getter 误注册 Obx          | 统一走 `rawValue`                   |
| `containsKey` 等读路径多次 `[]`            | `_readTracked` 单次注册依赖            |

```dart
list.update((items) {
  items.removeAt(0);
  items.add(99);
}); // 只 notify 一次

map.batchUpdate((m) {
  m.remove('old');
  m['new'] = 1;
});
```

对列表页、购物车、表单动态字段等场景，这直接决定了 Obx 会不会「抖」。

### 4.3 生命周期：页面级 Rx 不应泄漏

`RxLifecycleMixin` 把页面里常见的四类资源绑在一起：

- `rx()` → Rx 变量
- `subscription()` → Stream / bindStream
- `listen()` → Rx 监听
- `worker()` → Workers

页面 `dispose` 时统一释放。配合 `select()` 在派生 Rx `close` 时自动取消父 Rx 上的 listen，避免派生状态泄漏。

### 4.4 peek：区分「读给 UI」和「读给副作用」

```dart
ever(count, (_) => log(count.peek)); // ✅ 不额外订阅 count

Obx(() => Text('${count.peek}')); // ❌ peek 不注册依赖，UI 不会更新
```

`toList()` / `toMap()` / `toSet()` 同理——快照读法，不污染 Obx 依赖图。

### 4.5 1.0.1：同帧合并与 Signal 热路径

**Obx 同帧 rebuild 合并：** 同一帧内连续改多个 Rx（如 `loading.value = true; error.value = null`
），以前可能触发多次 `setState`；现在通过 `scheduleFrameCallback` 合并为一次 rebuild。

**Signal 优化：** 无订阅者时不遍历 listener；单订阅走 fast path；`try/finally` 保证 listener 抛错后不卡在
busy 状态。

**API 收敛：** 集合 `addIf` 的条件类型由 `SignalCondition` 更名为 **`RxCondition`**，语义归属 Rx 模块而非
Signal。

---

## 5. 和主流方案怎么选？

没有银弹，只有场景匹配。

### 选 ns_obx，如果你……

- 想要 **字段级 rebuild**，又不想引入 GetX 全家桶
- 正在 **从 GetX 迁移**，希望改 import 就能跑
- 做 **插件 / SDK**，对依赖体积敏感（~15KB）
- 已有 **Riverpod / get_it** 做 DI，只缺一个好用的响应式层
- 页面状态为主，Controller 里几个 `.obs` + 若干 `Obx` 就够

### 暂不选 ns_obx，如果你……

- 需要 **编译时安全** 和复杂依赖图 → Riverpod
- 需要 **内置路由 + DI + 主题** 一体化 → GetX 或自建架构
- 团队规范要求 **单向数据流 + 显式 Event** → Bloc

### 和 Provider / Riverpod 的关系

不是替代，是 **互补**：

```
Riverpod（DI + 全局状态 + 编译时检查）
    +
ns_obx（Controller 内的字段级 Rx + Obx）
    =
架构清晰 + UI 精细更新
```

---

## 6. 上手：三分钟验证值不值

**安装：**

```yaml
dependencies:
  ns_obx: ^1.0.5
```

**最小示例：**

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

**GetX 迁移：** 把 `import 'package:get/get.dart'` 换成 `import 'package:ns_obx/ns_obx.dart'`
，其余大部分代码不动。

**跑 Demo：**

```bash
cd example
flutter pub get
flutter run
```

6 个 Tab 覆盖 ns_bind、ns_store、ns_refresh 与 **ns_obx Obx Tab**（集合、sweep、bindStream）——建议至少过一遍
**Obx** Tab。

---

## 7. 写 ns_obx 时的五条铁律

从 356 项测试和 example 边界页沉淀出的实践：

1. **Obx 里只读 `.value`，写在回调里** — 避免 build 期间 `setState`
2. **改对象字段用 `update()`** — `user.value.name = 'x'` 不会触发 UI
3. **页面 Rx 用 `RxLifecycleMixin`** — 别靠 GC 碰运气
4. **集合多次改用 `update` / `batchUpdate`** — 少 rebuild 几次是一次，列表页可能是几百次
5. **副作用用 Workers / `listen` / `peek`** — 别把 Obx 当副作用容器

集合是 **容器级订阅**：读 `list[0]` 订阅的是整个 list。要 item 级更新，拆 Rx 或拆 Obx。

---

## 8. 现状：1.0.1 带来了什么？

**[ns_obx](https://pub.dev/packages/ns_obx)** 当前推荐版本 **1.0.5**：

| 模块      | 内容                                                       |
|---------|----------------------------------------------------------|
| Rx      | 基础类型、可空、`RxList/Map/Set`、`RxCondition`                   |
| UI      | Obx、ObxValue、增量依赖扫描、**同帧 rebuild 合并**                    |
| 生命周期    | RxLifecycleMixin                                         |
| Workers | ever / once / debounce（trailing + **leading**）/ interval |
| Signal  | 独立事件原语、**热路径优化**                                         |
| 质量      | 356 tests，analyze clean                                  |

**1.0.0** 是首个正式 pub 版（集合批量 API、Workers、Obx stale 依赖修复等）；**1.0.1** 聚焦性能打磨与 API
命名收敛。**1.0.4** 引入 `RxLifecycleMixin` 与 `RxDisposable`；**1.0.5** 改进 pub.dev 元数据与文档。

文档：[README_CN.md](README_CN.md) · [CHANGELOG_CN.md](CHANGELOG_CN.md) · [example/](example/)

---

## 9. 结语：优化状态管理，先优化「粒度」

状态管理方案的争论，很多时候是在争「谁的架构更完整」。  
但对大量 Flutter 页面来说，更实在的优化是：

**让 UI 只在必要的地方 rebuild，让副作用和 UI 分开，让页面销毁时资源真的释放。**

ns_obx 不做全家桶，只把这三件事做到极致轻量地做好。  
如果你认同「响应式层应该独立、可测、可迁移」，值得一试。

```yaml
dependencies:
  ns_obx: ^1.0.5
```

---

*MIT License · 欢迎 [Issue](https://pub.dev/packages/ns_obx) 与 PR*
