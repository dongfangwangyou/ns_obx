import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates nullable reactive types and null-safety helpers.
class NullablePage extends StatefulWidget {
  const NullablePage({super.key});

  @override
  State<NullablePage> createState() => _NullablePageState();
}

class _NullablePageState extends State<NullablePage> {
  late final nullableInt = RxnInt();
  late final nullableDouble = RxDoubleNullable();
  late final nullableString = RxStringNullable();
  late final nullableBool = RxBoolNullable();

  @override
  void dispose() {
    nullableInt.close();
    nullableDouble.close();
    nullableString.close();
    nullableBool.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner(),
          const SizedBox(height: 24),
          _sectionTitle('1. RxnInt (Rx<int?>)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Value: ${nullableInt.value?.toString() ?? "null"}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    )),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton(
                      onPressed: () => nullableInt.value = 42,
                      child: const Text('Set 42'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableInt.value = null,
                      child: const Text('Set null'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableInt + 10,
                      child: const Text('+10 (op)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. RxStringNullable (Rx<String?>)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Value: ${nullableString.value ?? "null"}',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Set string',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => nullableString.value = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => nullableString.value = null,
                      child: const Text('null'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('3. RxBoolNullable (Rx<bool?>)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Value: ${nullableBool.value?.toString() ?? "null"}',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                const SizedBox(height: 4),
                Obx(() => Text(
                      'isTrue: ${nullableBool.isTrue}  |  isFalse: ${nullableBool.isFalse}',
                      style: Theme.of(context).textTheme.bodySmall,
                    )),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => nullableBool.value = true,
                      child: const Text('true'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => nullableBool.value = false,
                      child: const Text('false'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableBool.value = null,
                      child: const Text('null'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableBool.toggle(),
                      child: const Text('toggle()'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('4. RxnDouble (Rx<double?>)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Obx(() => Text(
                      'Value: ${nullableDouble.value?.toStringAsFixed(1) ?? "null"}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    )),
                const SizedBox(height: 8),
                Obx(() {
                  final result = nullableDouble + 3.5;
                  return Text(
                    'After +3.5: ${result?.value?.toStringAsFixed(1) ?? "null (op returned null)"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton(
                      onPressed: () => nullableDouble.value = 3.14,
                      child: const Text('Set 3.14'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableDouble.value = null,
                      child: const Text('Set null'),
                    ),
                    OutlinedButton(
                      onPressed: () => nullableDouble - 1.0,
                      child: const Text('-1.0 (op)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('5. peek / null-safe read'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final v = nullableInt.value;
                  final display = v != null
                      ? 'value: $v'
                      : 'default (??): ${v ?? -1}';
                  return Text(
                    display,
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                }),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('peek: ${nullableInt.peek}')),
                    );
                  },
                  child: const Text('Show peek (no Obx dep)'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final v = nullableInt.value;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            v != null ? 'Value: $v' : 'Value is null (getOrThrow would throw)',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Read value (null-safe)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'All nullable variables start as null. '
              'Set values and observe reactive updates.',
              style: TextStyle(fontSize: 13),
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
