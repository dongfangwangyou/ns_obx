import 'package:flutter/material.dart';

import 'pages/autodispose_page.dart';
import 'pages/basic_page.dart';
import 'pages/boundaries_page.dart';
import 'pages/collection_page.dart';
import 'pages/event_channel_page.dart';
import 'pages/nullable_page.dart';
import 'pages/signal_page.dart';
import 'pages/workers_page.dart';

void main() => runApp(const MyApp());

/// Minimal yet comprehensive example app for ns_obx.
///
/// Demonstrates reactive variables, collections, nullable types, Signal,
/// EventChannel, lifecycle management, Workers, and usage boundaries.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ns_obx Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _demos = [
    _DemoItem(
      title: 'Basic Rx',
      subtitle: '.obs, Obx, ObxValue, peek',
      icon: Icons.looks_one,
      page: BasicPage(),
    ),
    _DemoItem(
      title: 'Collections',
      subtitle: 'RxList, RxMap, RxSet, batch update',
      icon: Icons.list_alt,
      page: CollectionPage(),
    ),
    _DemoItem(
      title: 'Nullable',
      subtitle: 'RxnInt, RxStringNullable, null safety',
      icon: Icons.all_inclusive,
      page: NullablePage(),
    ),
    _DemoItem(
      title: 'Signal',
      subtitle: 'Event primitive, pause/resume/close',
      icon: Icons.wifi_tethering,
      page: SignalPage(),
    ),
    _DemoItem(
      title: 'EventChannel',
      subtitle: 'Type-safe event bus on Signal',
      icon: Icons.cable,
      page: EventChannelPage(),
    ),
    _DemoItem(
      title: 'AutoDispose',
      subtitle: 'RxLifecycleMixin resource cleanup',
      icon: Icons.auto_delete,
      page: AutoDisposePage(),
    ),
    _DemoItem(
      title: 'Workers',
      subtitle: 'ever, once, debounce, interval',
      icon: Icons.work_outline,
      page: WorkersPage(),
    ),
    _DemoItem(
      title: 'Boundaries',
      subtitle: 'Best practices and pitfalls',
      icon: Icons.gpp_good,
      page: BoundariesPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _demos[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selected.title),
            Text(
              selected.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'ns_obx',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lightweight reactive state management',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _demos.length; i++)
              ListTile(
                leading: Icon(_demos[i].icon),
                title: Text(_demos[i].title),
                subtitle: Text(_demos[i].subtitle),
                selected: _selectedIndex == i,
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
      body: selected.page,
    );
  }
}

class _DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  const _DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}
