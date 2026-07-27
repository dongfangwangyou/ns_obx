[English](README.md)

# ns_obx

[![pub version](https://img.shields.io/pub/v/ns_obx)](https://pub.dev/packages/ns_obx)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**轻量级** **高性能** Flutter **响应式**状态管理库。从 GetX 响应式核心剥离重构，保留 `.obs` + `Obx`
用法，修复多项历史问题，零第三方依赖，打包体积 **<15KB**。

> 只做「Rx 变量 + Obx 组件 + 生命周期工具」，不含路由 / DI / 国际化。用过 GetX 响应式层可几乎零成本迁移。

---

## 特性

|             |                                                            |
|-------------|------------------------------------------------------------|
| **极小体积**    | 打包后体积 <15KB                                                |
| **零依赖**     | 仅依赖 Flutter SDK                                            |
| **类型安全**    | 完整泛型与编译时类型检查                                               |
| **高性能**     | 字段级 rebuild；同帧多 Rx 变化合并为一次 `setState`                      |
| **GetX 兼容** | `.obs`、`Obx`、`RxList/Map/Set` 用法一致                         |
| **Workers** | `ever` / `once` / `debounce`（leading/trailing）/ `interval` |
| **Signal**  | 内置轻量事件原语，可脱离 Obx 单独使用                                      |
| **生命周期**    | `RxLifecycleMixin` 自动释放 Rx / 订阅 / Worker                   |
| **集合优化**    | 批量 `update` / `batchUpdate`、no-op 跳过无效通知                   |

---

## 环境要求

|          | 版本               |
|----------|------------------|
| Dart SDK | `>=3.4.0 <4.0.0` |
| Flutter  | `>=3.13.0`       |

---

## 安装

```yaml
dependencies:
  ns_obx: ^1.0.5
```

```bash
flutter pub get
```

---

## 快速开始

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

**要点：** `Obx` 的 builder 内**只读** `.value`；改值放在 `onPressed` 等回调里。

---

## 目录

- [导出内容](#导出内容)
- [核心模块](#核心模块)
- [API 速查](#api-速查)
- [页面级生命周期](#页面级生命周期-rxlifecyclemixin)
- [GetX 迁移](#getx-迁移)
- [选型对比](#选型对比)
- [最佳实践](#最佳实践)
- [示例应用](#示例应用)
- [进阶：Obx 依赖追踪与 rebuild](#进阶obx-依赖追踪与-rebuild)
- [更新日志](#更新日志)

---

## 导出内容

`import 'package:ns_obx/ns_obx.dart';` 包含：

| 模块          | 主要内容                                                                                         |
|-------------|----------------------------------------------------------------------------------------------|
| **Rx**      | `Rx<T>`、`RxBool/Int/Double/String`、可空变体、`RxCollection`、`RxList/Map/Set`、`.obs`、`RxCondition` |
| **Obx**     | `Obx`、`ObxValue`、`ObxWidget`、`RxLifecycleMixin`                                              |
| **Workers** | `ever`、`once`、`debounce`、`interval`、`Worker`                                                 |
| **Signal**  | `Signal<T>`、`SignalSubscription`（事件通知，无需 Obx）                                                |

---

## 核心模块

```
Signal（事件广播，可选独立使用）
  └── Rx（响应式状态 + subject）
        ├── RxCollection → RxList / RxMap / RxSet
        ├── Obx（UI 依赖追踪 + rebuild）
        └── Workers（Rx 副作用：防抖 / 节流 / 监听）
```

| 需求            | 选用                       |
|---------------|--------------------------|
| UI 随数据变       | **Rx + Obx**             |
| 防抖搜索、日志、一次性回调 | **Workers** 或 `listen()` |
| 纯事件、不驱动 UI    | **Signal**               |
| 页面销毁自动清理      | **RxLifecycleMixin**     |

---

## API 速查

### 响应式变量

```dart
final count = 0.obs; // RxInt
final name = 'hello'.obs; // RxString
final flag = true.obs; // RxBool
final user = Rx<User>(User()); // Rx<T>

final n = RxnInt(); // Rx<int?>，初始 null
final list = <int>[1, 2].obs; // RxList
final map = {'a': 1}.obs; // RxMap
final set = {1, 2}.obs; // RxSet
```

可空类型扩展（`RxNullable` / `RxnInt` 等）：`isNull`、`let`、`ifNull`、`getOrElse`、`getOrThrow`。

```dart
final title = RxStringNullable();
title.getOrElse('Untitled');
title.let((v) => print(v.length));
```

### Obx / ObxValue

```dart
// 只读展示
Obx(() => Text('${count.value}'));

// 同帧内改多个 Rx，Obx 只 rebuild 一次
void onSubmit() {
  loading.value = true;
  error.value = null;
  // 两次赋值 → 一次 setState
}

// 局部 Rx 绑定控件
ObxValue<RxBool>(
  (data) => Switch(value: data.value, onChanged: (v) => data.value = v),
  false.obs,
);
```

### 读写与工具

```dart
count.value = 1; // 写（触发订阅者）
count.value++; // 读 + 写
print(count.peek); // 读当前值，不注册 Obx 依赖

user.update((u) => u.name = 'Bob'); // 改对象内部字段
final nameRx = user.select((u) => u.name); // 派生 Rx（需管理 close）
count.bindStream(stream); // 返回 StreamSubscription
list.toList(); map.toMap(); set.toSet(); // 快照，不注册依赖
```

### 集合批量更新

| 类型       | API               | 说明                      |
|----------|-------------------|-------------------------|
| `RxList` | `update(fn)`      | 回调内多次修改，合并为一次通知         |
| `RxMap`  | `batchUpdate(fn)` | 同上（避免与 `Map.update` 冲突） |
| `RxSet`  | `update(fn)`      | 回调参数为 `Set<E>`          |

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

集合还支持 `assign` / `assignAll`、`addIf` / `addAllIf`；写操作在内容未变时会跳过无效 `refresh`。

`addIf` / `addAllIf` 的 `condition` 可为 `bool` 或延迟求值的 `RxCondition`（`bool Function()`）：

```dart
list.addIf(() => user.value.isAdmin, item);
list.addAllIf(true, [1, 2, 3]);
```

### Signal（独立事件通知）

无需 Obx，适合模块内 pub-sub、生命周期钩子等：

```dart
final events = Signal<String>();
final sub = events.listen((msg) => print(msg));
events.emit('hello');
await sub.cancel();
events.close();
```

| API                           | 说明                |
|-------------------------------|-------------------|
| `listen` / `emit`             | 订阅与发送             |
| `pause` / `resume` / `cancel` | 订阅控制              |
| `close`                       | 关闭；`value` 保留最后一条 |
| `stream`                      | 适配 `Stream<T>`    |

> Signal 是新订阅者不 replay 的 hot 事件源；无订阅者时 `emit` 只更新 `value` 不遍历
> listener；需要「当前值 + UI 更新」请用 Rx。

#### 用 Signal 实现类型安全的事件通道（EventChannel）

Signal 不 replay 的特性非常适合做一次性事件总线。下面是一个零依赖、完全类型安全的 `EventChannel<T>`：

```dart
class EventChannel<T> {
  final Signal<T> _signal = Signal<T>();

  /// 发送事件
  void emit(T event) => _signal.emit(event);

  /// 订阅事件
  SignalSubscription<T> on(void Function(T event) handler) =>
      _signal.listen(handler);

  /// 关闭通道
  void close() => _signal.close();
}
```

使用示例：

```dart
// 1. 定义业务事件通道
class AuthEvents {
  AuthEvents._();

  static final logout = EventChannel<LogoutEvent>();
  static final sessionExpired = EventChannel<SessionExpiredEvent>();
}

// 2. 订阅（通常在 initState / 路由监听中）
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

// 3. 发送事件（任意位置）
AuthEvents.logout.emit(LogoutEvent());
```

> 为什么不用 Rx？Rx 会 replay 当前值给新订阅者，容易导致事件被重复消费；Signal
> 只通知订阅之后发生的事件，更适合「命令/副作用」类通信。

### Workers

```dart
class _PageState extends State<Page> with RxLifecycleMixin {
  late final query = rx(''.obs);

  @override
  void initState() {
    super.initState();
    // 尾随 debounce：停止输入 300ms 后搜索（默认）
    worker(debounce(query, _search, time: const Duration(milliseconds: 300)));
    // leading debounce：首次输入立即搜索，窗口内后续忽略
    worker(debounce(query, _preview, leading: true, time: const Duration(milliseconds: 300)));
    worker(ever(count, (v) => print(v)));
    worker(once(count, (_) => _initOnce()));
  }
}
```

| API        | 行为                                                                  |
|------------|---------------------------------------------------------------------|
| `ever`     | 每次变化调用（不含初始值）                                                       |
| `once`     | 首次变化后自动取消                                                           |
| `debounce` | 默认**尾随**：静默 `time` 后调用最后一次值；`leading: true` 为**leading**（窗口内首次立即调用） |
| `interval` | 每 `time` 至多一次（节流，窗口内首次立即触发）                                         |

---

## 页面级生命周期（RxLifecycleMixin）

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
  // dispose 时自动 close Rx、cancel 订阅、dispose Worker
}
```

| 方法                  | 作用                      |
|---------------------|-------------------------|
| `rx(reactive)`      | 注册 Rx，dispose 时 `close` |
| `subscription(sub)` | 注册 `StreamSubscription` |
| `listen(rx, fn)`    | 监听 Rx 并自动追踪订阅           |
| `worker(w)`         | 注册 Worker               |

---

## GetX 迁移

```dart
// import 'package:get/get.dart';
import 'package:ns_obx/ns_obx.dart';

final count = 0.obs;
Obx(() => Text('${count.value}'));
```

主要差异：ns_obx **不含** `GetMaterialApp` / 路由 / `Get.put`；需要 DI 请自行选型或搭配生态内 DI 方案。

---

## 选型对比

|         |     ns_obx     | Provider / Riverpod |  GetX  |
|---------|:--------------:|:-------------------:|:------:|
| 体积      |     ~15KB      |        50KB+        | 200KB+ |
| 响应粒度    |    **字段级**     |      Widget 级       |  字段级   |
| DI / 路由 |       ❌        |       ✅ / 部分        |   ✅    |
| 学习成本    | 极低（GetX 用户零成本） |         低~中         |   中    |

```dart
// Provider：改 name 时整个 Consumer rebuild
// ns_obx：每个 Obx 只依赖自己读到的 Rx
Obx(() => Text(user.value.name)); // 只重建这一行
Obx(() => Text('${user.value.age}')); // age 变才重建
```

**适合：** 局部状态、GetX 迁移、插件/SDK、与 Riverpod 等 DI 组合。  
**不适合：** 需要内置 DI/路由/编译时安全的大型架构（选 Riverpod 等）。

---

## 最佳实践

| ✅ 推荐                             | ❌ 避免                             |
|----------------------------------|----------------------------------|
| Obx builder 内**只读** `.value`     | builder 内写 `count.value++`       |
| 改值放在 `onPressed` / Controller    | async 回调里读 `.value` 期望 Obx 订阅    |
| 对象字段变更用 `update()`               | `user.value.name = 'x'`（引用不变不触发） |
| 页面 Rx 用 `RxLifecycleMixin`       | 已 `close()` 的 Rx 仍被 Obx 使用       |
| 副作用用 `peek` / Workers / `listen` | Obx 内用 `peek` 期望 rebuild         |
| 集合多次修改用 `update` / `batchUpdate` | 循环改集合触发多次 rebuild                |
| `select()` 派生 Rx 随页面 `close`     | 派生 Rx 泄漏不释放                      |

**集合粒度：** 读 `list[0]` 或 `map['k']` 订阅的是**整个容器**；单项精细更新请拆成多个 Rx 或多个 Obx。

**条件分支：** Obx 内 `if/else` 切换后，旧分支的 Rx 依赖会自动移除（增量依赖扫描）。

更多细节见仓库 **[example/](../../example/)** 中 **Obx** Tab（集合、`RxCondition`、条件分支 sweep、`bindStream`）。

---

## 常见陷阱

### 1. 在 `Obx` builder 中写 `.value`

```dart
// ❌ 错误：不会触发 rebuild，且可能触发断言
Obx(() {
  count.value++;
  return Text('${count.value}');
});

// ✅ 正确：builder 内只读
Obx(() => Text('${count.value}'));
```

### 2. async 回调里读 `.value` 期望 Obx 订阅

```dart
// ❌ 错误：Future 回调不在 Obx build 执行栈中
Obx(() => FutureBuilder(
  future: fetch(user.value.id), // 不会订阅 user
  builder: ...,
));

// ✅ 正确：在 Obx 内直接读取
Obx(() => Text('${user.value.name}'));
```

### 3. 修改对象内部字段不触发更新

```dart
// ❌ 错误：引用未变
user.value.name = 'Bob';

// ✅ 正确：触发 setter / refresh
user.update((u) => u.name = 'Bob');
```

### 4. 派生 Rx 泄漏

```dart
// ❌ 错误：derived 不会随页面释放
final derived = user.select((u) => u.name);

// ✅ 正确：用 RxLifecycleMixin / RxDisposable 注册
final derived = rx(user.select((u) => u.name));
// 或用于非 Widget 作用域：
final disposable = RxDisposable();
final derived = disposable.rx(user.select((u) => u.name));
```

### 5. 集合 item 级读取订阅的是整个容器

```dart
// 订阅的是整个 list，任何元素变化都会 rebuild
Obx(() => Text('${list[0]}'));

// ✅ 若只需单项精细更新，拆成独立 Rx
final firstItem = 0.obs;
Obx(() => Text('${firstItem.value}'));
```

### 6. 已 `close()` 的 Rx 仍被 Obx 使用

```dart
// ❌ 错误：count 关闭后 Obx 会读到无效状态
count.close();
return Obx(() => Text('${count.value}'));

// ✅ 正确：让生命周期 mixin 在 dispose 时统一关闭
class _PageState extends State<Page> with RxLifecycleMixin { ... }
```

---

## 示例应用

### 最小示例（推荐上手）

包内 **[example/](./example/)** 目录提供只依赖 `ns_obx` 的最小可运行应用：

```bash
cd dependence/ns_obx/example
flutter pub get
flutter run
```

包含 **Counter**（`.obs` + `Obx`）和 **Search**（`debounce` + `RxLifecycleMixin`）两页。

### 完整综合 Demo

仓库根目录 **[example/](../../example/)** 为多包综合 Demo（`ns_obx` / `ns_bind` / `ns_store` /
`ns_refresh`）：

```bash
cd example
flutter pub get
flutter run
```

| Tab       | 演示内容                                                                         |
|-----------|------------------------------------------------------------------------------|
| Counter   | `Obx`、`.obs`、多类型 Rx、`RxList` 历史（via ns_bind）                                 |
| Users     | 列表与表单响应式（via ns_bind）                                                        |
| BindScope | 作用域与生命周期（via ns_bind）                                                        |
| Store     | 分页 Store（via ns_store）                                                       |
| Refresh   | 下拉刷新分页（via ns_refresh）                                                       |
| **Obx**   | **ns_obx 专项**：集合 `update`/`addIf`、`RxCondition`、条件分支 sweep、`bindStream`、同帧合并 |

---

## 进阶：Obx 依赖追踪

- **增量 sweep**：`ObxObserver.begin/endDependencySweep` 移除 stale 依赖
- **两类订阅**：Obx 读 `.value` / `readTracked` 走 proxy；`bindStream` / `select` 走 `ReactiveMixin.linkSubscription`
- **同帧合并**：同帧多 Rx 变化合并为一次 `setState`

完整分层、数据流与 1.0.2 架构说明见 **[ARCHITECTURE.md](ARCHITECTURE.md)**。

---

## 项目结构

```
lib/
├── ns_obx.dart              # 统一导出
└── src/
    ├── rx/                  # RxInterface、RxCollection、RxSubjectMixin、ReactiveMixin
    ├── signals/signal.dart  # Signal 事件原语
    ├── workers/workers.dart # Workers 副作用
    ├── lifecycle/           # RxLifecycleMixin、RxDisposable
    └── obx/                 # Obx、ObxObserver、ObxValue
```

---

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)。

**1.0.2** — `RxProxyContract`、`RxCollection` 基类、`ObxObserver` 内联 proxy 依赖表、`linkSubscription` 迁入 `ReactiveMixin`。

**1.0.1** — Obx 同帧 rebuild 合并、Signal 热路径优化、`debounce(leading: true)`、`RxCondition`。

**1.0.0** — 首个正式版：Obx 增量依赖扫描、集合写操作与批量 API、Workers、`peek`。

---

## 许可证

[MIT License](LICENSE)

欢迎 Issue 与 Pull Request。
