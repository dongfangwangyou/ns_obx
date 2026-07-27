import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates using Signal as a type-safe event channel / lightweight event bus.
///
/// Includes:
/// - A global event channel shared across the app.
/// - A page-local event channel for self-contained pub-sub.
/// - Manual subscription lifecycle (cancel on dispose).
class EventChannelPage extends StatefulWidget {
  const EventChannelPage({super.key});

  @override
  State<EventChannelPage> createState() => _EventChannelPageState();
}

/// A typed event payload.
class LikeEvent {
  final String itemId;
  final DateTime timestamp;

  LikeEvent(this.itemId) : timestamp = DateTime.now();
}

/// A type-safe event channel built on top of Signal.
class EventChannel<T> {
  final Signal<T> _signal = Signal<T>();

  /// Current subscriber count.
  int get length => _signal.length;

  /// Emit an event to all current subscribers.
  void emit(T event) => _signal.emit(event);

  /// Subscribe to events.
  SignalSubscription<T> on(void Function(T event) handler) =>
      _signal.listen(handler);

  /// Close the channel and release resources.
  void close() => _signal.close();
}

/// Global event channels for cross-module communication.
class AppEvents {
  AppEvents._();
  static final EventChannel<LikeEvent> like = EventChannel<LikeEvent>();
}

class _EventChannelPageState extends State<EventChannelPage> {
  /// Page-local event channel: only lives while this page is mounted.
  late final EventChannel<String> _localChannel;

  final _log = <String>[].obs;
  SignalSubscription<LikeEvent>? _globalSub;
  SignalSubscription<String>? _localSub;

  @override
  void initState() {
    super.initState();
    _localChannel = EventChannel<String>();

    // Subscribe to global like events.
    _globalSub = AppEvents.like.on((event) {
      _log.add(
        '[Global] Liked ${event.itemId} at ${event.timestamp.toLocal()}',
      );
    });

    // Subscribe to page-local events.
    _localSub = _localChannel.on((message) {
      _log.add('[Local] $message');
    });
  }

  @override
  void dispose() {
    _globalSub?.cancel();
    _localSub?.cancel();
    _localChannel.close();
    _log.close();
    super.dispose();
  }

  void _emitGlobalLike() {
    AppEvents.like.emit(LikeEvent('item-${DateTime.now().millisecond}'));
  }

  void _emitLocalEvent() {
    _localChannel.emit('Hello from local channel #${_log.length + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Global EventChannel'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscribers: ${AppEvents.like.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _emitGlobalLike,
                  child: const Text('Emit Global LikeEvent'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open another tab and come back: this channel survives '
                  'because it is static.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. Page-local EventChannel'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscribers: ${_localChannel.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _emitLocalEvent,
                  child: const Text('Emit Local String Event'),
                ),
                const SizedBox(height: 8),
                Text(
                  'This channel is created in initState and closed in dispose.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('3. Event Log'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() => Row(
                      children: [
                        Text(
                          'Log (${_log.length} entries)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _log.clear(),
                          child: const Text('Clear'),
                        ),
                      ],
                    )),
                const Divider(height: 8),
                Obx(() {
                  if (_log.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No events yet. Tap a button above to emit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _log.length,
                      itemBuilder: (_, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '#${i + 1} ${_log[i]}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('4. Key Takeaway'),
          const SizedBox(height: 8),
          _card(
            child: Text(
              'Signal does not replay events to new subscribers, so it is a '
              'natural fit for one-shot event channels. '
              'For shared UI state that new observers should see immediately, '
              'use Rx/Obs instead.',
              style: Theme.of(context).textTheme.bodyMedium,
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
