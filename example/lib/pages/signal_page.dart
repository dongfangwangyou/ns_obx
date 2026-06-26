import 'package:flutter/material.dart';
import 'package:ns_obx/ns_obx.dart';

/// Demonstrates the Signal event system: creating signals,
/// subscribing, adding events, pause/resume, and lifecycle callbacks.
class SignalPage extends StatefulWidget {
  const SignalPage({super.key});

  @override
  State<SignalPage> createState() => _SignalPageState();
}

class _SignalPageState extends State<SignalPage> {
  late final Signal<String> _signal;
  SignalSubscription<String>? _subscription;

  final _log = <String>[].obs;

  int _eventCounter = 0;

  @override
  void initState() {
    super.initState();
    _signal = Signal<String>(
      onListen: () => _log.add('[Lifecycle] onListen — new subscriber'),
      onPause: () => _log.add('[Lifecycle] onPause'),
      onResume: () => _log.add('[Lifecycle] onResume'),
      onCancel: () => _log.add('[Lifecycle] onCancel — subscription cancelled'),
    );

    _subscription = _signal.listen(
      (event) => _log.add('[Event] Received: "$event"'),
      onDone: () => _log.add('[Done] Signal closed'),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _signal.close();
    _log.close();
    super.dispose();
  }

  void _addEvent() {
    _eventCounter++;
    _signal.add('Event #$_eventCounter');
  }

  void _pauseResume() {
    if (_subscription?.isPaused ?? false) {
      _subscription?.resume();
      _log.add('[Action] Resumed subscription');
    } else {
      _subscription?.pause();
      _log.add('[Action] Paused subscription');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Signal Basics'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                Text(
                  'Status: ${_signal.isClosed ? "CLOSED" : "ACTIVE"} | '
                  'Listeners: ${_signal.length} | '
                  'Paused: ${_subscription?.isPaused ?? false}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Obx(() {
                  _log.length;
                  return Text(
                    'Last value: ${_signal.value ?? "(none)"}',
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                }),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilledButton(
                      onPressed: _signal.isClosed ? null : _addEvent,
                      child: const Text('Add Event'),
                    ),
                    OutlinedButton(
                      onPressed: _signal.isClosed ? null : _pauseResume,
                      child: Text(
                        (_subscription?.isPaused ?? false) ? 'Resume' : 'Pause',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _signal.isClosed
                          ? null
                          : () {
                              _subscription?.cancel();
                              _log.add('[Action] Subscription cancelled');
                              setState(() {});
                            },
                      child: const Text('Cancel Sub'),
                    ),
                    OutlinedButton(
                      onPressed: _signal.isClosed
                          ? null
                          : () {
                              _signal.close();
                              _log.add('[Action] Signal closed');
                              setState(() {});
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Close Signal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('2. Event Log'),
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
                        'No events yet. Tap "Add Event" to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _log.length,
                      itemBuilder: (_, i) {
                        final entry = _log[i];
                        final isLifecycle = entry.startsWith('[Lifecycle]');
                        final isDone = entry.startsWith('[Done]');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${i + 1}  ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: isLifecycle
                                        ? Colors.blue.shade700
                                        : isDone
                                            ? Colors.red.shade700
                                            : null,
                                  ),
                                ),
                              ),
                            ],
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
          _sectionTitle('3. Key Signal API'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _apiRow('signal.listen(onData)', 'Subscribe to events'),
                _apiRow('signal.add(event)', 'Emit an event to subscribers'),
                _apiRow('subscription.pause()', 'Pause receiving events'),
                _apiRow('subscription.resume()', 'Resume receiving events'),
                _apiRow('subscription.cancel()', 'Cancel subscription'),
                _apiRow('signal.close()', 'Close signal, notify onDone'),
                _apiRow('signal.value', 'Get the last emitted value'),
                _apiRow('signal.length', 'Number of active subscribers'),
                _apiRow('signal.hasListeners', 'Whether has subscribers'),
                _apiRow('signal.isClosed', 'Whether signal is closed'),
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

  Widget _apiRow(String method, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              method,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.indigo,
              ),
            ),
          ),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
