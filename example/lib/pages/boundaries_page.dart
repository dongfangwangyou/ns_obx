import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates README「使用边界与注意事项」中的推荐写法。
class BoundariesPage extends StatefulWidget {
  const BoundariesPage({super.key});

  @override
  State<BoundariesPage> createState() => _BoundariesPageState();
}

class _BoundariesPageState extends State<BoundariesPage>
    with RxLifecycleMixin {
  // select 生命周期：父 Rx 与派生 Rx 均用 rx() 注册
  late final user = rx(Rx(_DemoUser(name: 'Alice', score: 10)));
  late final scoreRx = rx(user.select((u) => u.score));

  final showBranchA = true.obs;
  final branchA = 0.obs;
  final branchB = 100.obs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Obx 只读不写'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ 在 onPressed 中写 Rx；Obx builder 内只读 .value',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Obx(() => Text(
                      'Counter: ${branchA.value}',
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => branchA.value++,
                  child: const Text('Increment (callback)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. 条件分支 — 只保留当前依赖'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() {
                  if (showBranchA.value) {
                    return Text('Branch A: ${branchA.value}');
                  }
                  return Text('Branch B: ${branchB.value}');
                }),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => showBranchA.toggle(),
                      child: Obx(() => Text(
                            showBranchA.value ? 'Switch to B' : 'Switch to A',
                          )),
                    ),
                    OutlinedButton(
                      onPressed: () => branchA.value++,
                      child: const Text('A + 1'),
                    ),
                    OutlinedButton(
                      onPressed: () => branchB.value++,
                      child: const Text('B + 1'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('3. select 生命周期（RxLifecycleMixin）'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '派生 Rx 与父 Rx 均通过 rx() 注册，页面 dispose 时自动 close',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Obx(() => Text('Score: ${scoreRx.value}')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => user.update((u) => u.score += 5),
                  child: const Text('user.update() +5'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('4. 自定义对象 — 用 update 而非原地改字段'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text('User: ${user.value.name}')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => user.update((u) => u.name = 'Bob'),
                  child: const Text("Rename to Bob (update)"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _DemoUser {
  String name;
  int score;

  _DemoUser({required this.name, required this.score});
}
