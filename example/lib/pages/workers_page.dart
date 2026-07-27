import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates Workers: ever, once, debounce, interval + RxLifecycleMixin.worker().
class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> with RxLifecycleMixin {
  late final _counter = rx(0.obs);
  late final _query = rx(''.obs);
  late final _onceFlag = rx(false.obs);

  late final _log = rx(<String>[].obs);

  @override
  void initState() {
    super.initState();

    worker(ever(_counter, (v) {
      _log.add('[ever] counter → $v');
    }));

    worker(debounce(
      _query,
      (q) => _log.add('[debounce] search "$q"'),
      time: const Duration(milliseconds: 500),
    ));

    worker(interval(
      _counter,
      (v) => _log.add('[interval] throttled at $v'),
      time: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: const Text(
              'Workers 用于 Rx 副作用（日志、网络请求等），不驱动 UI rebuild。'
              '本页通过 worker() 注册，页面 dispose 时自动释放。',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('1. Counter - ever + interval'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Counter: ${_counter.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => _counter.value++,
                      child: const Text('+1'),
                    ),
                    OutlinedButton(
                      onPressed: () => _counter.value = 0,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'ever: 每次变化记录 | interval: 2s 内至多触发一次',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. Search — debounce'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Type to search (500ms debounce)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => _query.value = v,
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      'Query: "${_query.value}"',
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('3. once'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Triggered: ${_onceFlag.value}',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    if (_onceFlag.value) return;
                    worker(once(_onceFlag, (v) {
                      _log.add('[once] first change → $v');
                    }));
                    _onceFlag.value = true;
                  },
                  child: const Text('Arm once() & trigger'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('4. Worker Log'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Obx(() => Text(
                          'Entries: ${_log.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _log.clear(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const Divider(height: 8),
                Obx(() {
                  if (_log.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Interact above to see worker callbacks.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Text(
                      _log[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
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
