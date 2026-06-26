import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates basic reactive variables: .obs creation, Obx widget,
/// value read/write, operators, peek, and ObxValue.
class BasicPage extends StatefulWidget {
  const BasicPage({super.key});

  @override
  State<BasicPage> createState() => _BasicPageState();
}

class _BasicPageState extends State<BasicPage> {
  late final count = 0.obs;
  late final name = 'ns_obx'.obs;
  late final isDark = false.obs;

  @override
  void dispose() {
    count.close();
    name.close();
    isDark.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Counter (.obs + Obx)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Count: ${count.value}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'peek (no Obx dep): ${count.peek}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Show peek in SnackBar'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => count.value--,
                      child: const Text('-1'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => count.value++,
                      child: const Text('+1'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => count + 5,
                      child: const Text('+5 (operator)'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => count.value = 0,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. RxString (text input)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Value: "${name.value}"',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                const SizedBox(height: 8),
                Obx(() => Text(
                      'Length: ${name.value.length} | Uppercase: ${name.value.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Edit name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => name.value = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('3. RxBool & ObxValue'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDark.isTrue ? Icons.dark_mode : Icons.light_mode,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDark.isTrue ? 'Dark Mode' : 'Light Mode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => isDark.toggle(),
                      child: const Text('Toggle'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => isDark.value = true,
                      child: const Text('Set True'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => isDark.value = false,
                      child: const Text('Set False'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('4. ObxValue (local state)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                ObxValue<RxBool>(
                  (data) => SwitchListTile(
                    title: const Text('Enable notifications'),
                    subtitle: Text(data.isTrue ? 'ON' : 'OFF'),
                    value: data.value,
                    onChanged: (v) => data.value = v,
                  ),
                  true.obs,
                ),
                const Divider(),
                ObxValue<RxDouble>(
                  (data) => Column(
                    children: [
                      Text(
                        'Volume: ${data.value.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: data.value,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: data.value.toStringAsFixed(0),
                        onChanged: (v) => data.value = v,
                      ),
                    ],
                  ),
                  50.0.obs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('5. RxInt Operators (read-only)'),
          const SizedBox(height: 8),
          _card(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _operatorChip(context, '*2', () => count * 2),
                _operatorChip(context, '/2', () => count / 2),
                _operatorChip(context, '%3', () => count % 3),
                _operatorChip(context, '~/3', () => count ~/ 3),
                _operatorChip(context, '&1', () => count & 1),
                _operatorChip(context, '|2', () => count | 2),
                _operatorChip(context, '^3', () => count ^ 3),
                _operatorChip(context, '<<1', () => count << 1),
                _operatorChip(context, '>>1', () => count >> 1),
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

  Widget _operatorChip(BuildContext context, String label, dynamic result) {
    return ActionChip(
      label: Text('$label = $result'),
      onPressed: () {},
    );
  }
}
