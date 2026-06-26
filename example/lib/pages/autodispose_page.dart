import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Entry widget — wraps the AutoDispose demo in a [Visibility] toggle
/// so we can mount and unmount the widget to prove that
/// [RxAutoDisposeMixin] cleans up resources on dispose.
class AutoDisposePage extends StatefulWidget {
  const AutoDisposePage({super.key});

  @override
  State<AutoDisposePage> createState() => _AutoDisposePageState();
}

class _AutoDisposePageState extends State<AutoDisposePage> {
  bool _mounted = true;

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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toggle the widget below to mount/unmount. '
                    'RxAutoDisposeMixin automatically cleans up '
                    'all Rx variables and stream subscriptions on dispose.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Toggle button
          Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() => _mounted = !_mounted);
              },
              icon: Icon(_mounted ? Icons.visibility_off : Icons.visibility),
              label: Text(_mounted ? 'Unmount Widget' : 'Mount Widget'),
            ),
          ),

          const SizedBox(height: 16),

          // Conditionally mount the demo widget
          if (_mounted) const _AutoDisposeDemoWidget(),

          if (!_mounted)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Widget unmounted.\nRxAutoDisposeMixin.dispose() has been called.\nAll resources released.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The actual demo widget using [RxAutoDisposeMixin].
class _AutoDisposeDemoWidget extends StatefulWidget {
  const _AutoDisposeDemoWidget();

  @override
  State<StatefulWidget> createState() => _AutoDisposeDemoWidgetState();
}

class _AutoDisposeDemoWidgetState extends State
    with RxAutoDisposeMixin {
  // All three are registered via rx() → auto-disposed
  late final _counter = rx(0.obs);
  late final _message = rx('Hello'.obs);
  late final _items = rx(<String>[].obs);

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Method 1: listen() — auto-tracks the subscription
    listen<int>(_counter, (val) {
      debugPrint('[AutoDispose] Counter changed: $val');
    });

    // Method 2: bindStream() + subscription() — register returned sub
    subscription(_message.bindStream(
      Stream<String>.periodic(
        const Duration(seconds: 2),
        (i) => 'Tick ${i + 1}',
      ),
    ));

    // Also a regular timer (for demo display; won't be cleaned up by mixin)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _counter.value++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // RxAutoDisposeMixin.dispose() auto-called via mixin —
    // closes _counter, _message, _items; cancels listen / bindStream subs
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Text('RxAutoDisposeMixin Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // Counter (auto-increments every second)
            Obx(() => Text(
              'Counter: ${_counter.value}',
              style: Theme.of(context).textTheme.headlineSmall,
            )),
            const SizedBox(height: 8),

            // Stream message
            Obx(() => Text(
              'Stream: ${_message.value}',
              style: Theme.of(context).textTheme.titleMedium,
            )),
            const SizedBox(height: 12),

            // Items list
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add item to list',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) _items.add(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _items.clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (_items.isEmpty) {
                return const Text('No items', style: TextStyle(color: Colors.grey));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _items.map((item) => Chip(label: Text(item))).toList(),
              );
            }),

            const Divider(height: 32),

            // Summary of registered resources
            const Text('Registered resources (auto-disposed):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
              '  • rx(_counter) — RxInt\n'
              '  • rx(_message) — RxString\n'
              '  • rx(_items) — RxList<String>\n'
              '  • listen(_counter, ...) — StreamSubscription\n'
              '  • subscription(bindStream(_message)) — StreamSubscription\n'
              '  • worker(debounce) — 见 Workers 页',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
