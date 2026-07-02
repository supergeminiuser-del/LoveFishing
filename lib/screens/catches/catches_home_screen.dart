import 'package:flutter/material.dart';

import '../trips/trip_list_screen.dart';
import 'catch_list_screen.dart';

/// Вкладка «Улов»: переключение между списком уловов и рыбалками (поездками).
class CatchesHomeScreen extends StatefulWidget {
  const CatchesHomeScreen({super.key});

  @override
  State<CatchesHomeScreen> createState() => _CatchesHomeScreenState();
}

class _CatchesHomeScreenState extends State<CatchesHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Улов'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Уловы'),
            Tab(text: 'Рыбалки'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CatchListScreen(),
          TripListScreen(),
        ],
      ),
    );
  }
}
