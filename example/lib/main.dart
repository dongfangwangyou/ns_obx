import 'package:flutter/material.dart';

import 'pages/basic_page.dart';
import 'pages/collection_page.dart';
import 'pages/nullable_page.dart';
import 'pages/signal_page.dart';
import 'pages/autodispose_page.dart';
import 'pages/workers_page.dart';
import 'pages/boundaries_page.dart';

void main() {
  runApp(const NsObxExampleApp());
}

/// Root app widget with Material 3 theme.
class NsObxExampleApp extends StatelessWidget {
  const NsObxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ns_obx Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

/// Tab-based home screen navigating between feature demos.
class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _pages = <Widget>[
    BasicPage(),
    CollectionPage(),
    NullablePage(),
    SignalPage(),
    AutoDisposePage(),
    WorkersPage(),
    BoundariesPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ns_obx Example'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Rx'),
            Tab(text: 'Collections'),
            Tab(text: 'Nullable'),
            Tab(text: 'Signal'),
            Tab(text: 'AutoDispose'),
            Tab(text: 'Workers'),
            Tab(text: 'Boundaries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _pages,
      ),
    );
  }
}
