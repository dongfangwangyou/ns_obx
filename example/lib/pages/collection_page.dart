import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates collection types: RxList, RxMap, RxSet.
/// Shows CRUD operations that trigger reactive UI updates.
class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  // Reactive collections
  final _items = <String>['Apple', 'Banana'].obs;
  final _scores = <String, int>{'Alice': 95, 'Bob': 87}.obs;
  final _tags = <String>{'dart', 'flutter'}.obs;

  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    _items.close();
    _scores.close();
    _tags.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- RxList ---
          _sectionTitle('1. RxList<String>'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                // Add item
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newItemController,
                        decoration: const InputDecoration(
                          hintText: 'New item',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (_newItemController.text.isNotEmpty) {
                          _items.add(_newItemController.text);
                          _newItemController.clear();
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('AddIf (true)'),
                      onPressed: () => _items.addIf(true, 'Cherry'),
                    ),
                    ActionChip(
                      label: const Text('AddIf (false)'),
                      onPressed: () => _items.addIf(false, 'Skipped'),
                    ),
                    ActionChip(
                      label: const Text('assign'),
                      onPressed: () => _items.assign('Reset'),
                    ),
                    ActionChip(
                      label: const Text('assignAll'),
                      onPressed: () => _items.assignAll(['X', 'Y', 'Z']),
                    ),
                    ActionChip(
                      label: const Text('Sort'),
                      onPressed: () => _items.sort(),
                    ),
                    ActionChip(
                      label: const Text('operator +'),
                      onPressed: () => _items + ['Grape', 'Mango'],
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Reactive list display
                Obx(() {
                  if (_items.isEmpty) {
                    return const Text('List is empty',
                        style: TextStyle(color: Colors.grey));
                  }
                  return Column(
                    children: [
                      Text('Count: ${_items.length}',
                          style: Theme.of(context).textTheme.bodySmall),
                      ..._items.asMap().entries.map((entry) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text('${entry.key + 1}'),
                        ),
                        title: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            _items.removeWhere((e) => e == entry.value);
                          },
                        ),
                      )),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- RxMap ---
          _sectionTitle('2. RxMap<String, int>'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Add Charlie'),
                      onPressed: () => _scores['Charlie'] = 78,
                    ),
                    ActionChip(
                      label: const Text('Increment Alice'),
                      onPressed: () {
                        _scores['Alice'] = (_scores['Alice'] ?? 0) + 1;
                      },
                    ),
                    ActionChip(
                      label: const Text('Remove Bob'),
                      onPressed: () => _scores.remove('Bob'),
                    ),
                    ActionChip(
                      label: const Text('assignAll'),
                      onPressed: () => _scores.assignAll({'Dave': 60, 'Eve': 72}),
                    ),
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: () => _scores.clear(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Obx(() {
                  if (_scores.isEmpty) {
                    return const Text('Map is empty',
                        style: TextStyle(color: Colors.grey));
                  }
                  return Table(
                    border: TableBorder.all(
                        color: Colors.grey.shade300),
                    columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFE8EAF6)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Name',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Score',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ..._scores.entries.map((e) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(e.key),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${e.value}'),
                          ),
                        ],
                      )),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- RxSet ---
          _sectionTitle('3. RxSet<String>'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Add "riverpod"'),
                      onPressed: () => _tags.add('riverpod'),
                    ),
                    ActionChip(
                      label: const Text('Add "dart" (dup)'),
                      onPressed: () => _tags.add('dart'),
                    ),
                    ActionChip(
                      label: const Text('Remove "flutter"'),
                      onPressed: () => _tags.remove('flutter'),
                    ),
                    ActionChip(
                      label: const Text('assign'),
                      onPressed: () => _tags.assign('only-me'),
                    ),
                    ActionChip(
                      label: const Text('assignAll'),
                      onPressed: () => _tags.assignAll({'a', 'b', 'c'}),
                    ),
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: () => _tags.clear(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Obx(() {
                  if (_tags.isEmpty) {
                    return const Text('Set is empty',
                        style: TextStyle(color: Colors.grey));
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _tags.remove(tag),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Batch update ---
          _sectionTitle('4. Batch update (update / batchUpdate)'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('List.update'),
                      onPressed: () {
                        _items.update((items) {
                          items.add('Batch');
                          items.removeWhere((e) => e == 'Apple');
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Map.batchUpdate'),
                      onPressed: () {
                        _scores.batchUpdate((map) {
                          map.remove('Bob');
                          map['Batch'] = 100;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Set.update'),
                      onPressed: () {
                        _tags.update((set) {
                          set.remove('dart');
                          set.add('batch');
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '上述操作合并为单次 refresh，见上方列表/表格/标签变化。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ));
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
