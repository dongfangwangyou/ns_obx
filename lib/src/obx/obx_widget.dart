import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../rx/rx.dart';
import 'obx_observer.dart';

/// UI 层中最小的响应式组件
/// 只需在回调的作用域内使用 Rx 变量，它会自动注册依赖和更新
///
/// 示例:
/// ```dart
/// final _name = "x".obs;
/// Obx(() => Text(_name.value)), ...;
/// ```
class Obx extends ObxWidget {
  final Widget Function() builder;

  const Obx(this.builder, {super.key});

  @override
  Widget build() => builder();
}

/// [ObxWidget] 自定义响应式组件的基类
///
/// 请参阅：
/// - [Obx] - 通用响应式组件
/// - [ObxValue] - 带本地状态的响应式组件
abstract class ObxWidget extends StatefulWidget {
  const ObxWidget({super.key});

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Function>.has('builder', build));
  }

  @override
  ObxState createState() => ObxState();

  @protected
  Widget build();
}

/// ObxWidget 的状态管理类
class ObxState extends State<ObxWidget> {
  late final ObxObserver _observer;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _observer = ObxObserver(_scheduleRebuild);
  }

  /// 同帧内多次 Rx 变化合并为一次 [setState]
  void _scheduleRebuild() {
    if (!mounted || _updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      try {
        setState(() {});
      } catch (e) {
        debugPrint('[NsObx] setState error: $e');
      }
    });
  }

  @override
  void dispose() {
    _updateScheduled = false;
    _observer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _observer.beginDependencySweep();
    try {
      return RxInterface.notifyDependents(_observer, widget.build);
    } finally {
      _observer.endDependencySweep();
    }
  }
}

/// 类似 Obx，但管理一个本地状态
/// 在构造函数中传递初始数据，适用于简单的局部状态，如开关、可见性、主题、按钮状态等
///
/// 示例:
/// ```dart
/// ObxValue((data) => Switch(
///   value: data.value,
///   onChanged: (flag) => data.value = flag,
/// ), false.obs)
/// ```
class ObxValue<T extends Rx<dynamic>> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {super.key});

  @override
  Widget build() => builder(data);
}
