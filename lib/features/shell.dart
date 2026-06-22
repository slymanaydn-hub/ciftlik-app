import 'package:flutter/material.dart';

import 'animals_page.dart';
import 'dashboard_page.dart';
import 'feed_page.dart';
import 'lambing_page.dart';
import 'money_page.dart';
import 'reports_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    AnimalsPage(),
    LambingPage(),
    FeedPage(),
    MoneyPage(),
    ReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Hayvanlar'),
          NavigationDestination(icon: Icon(Icons.child_care_outlined), selectedIcon: Icon(Icons.child_care), label: 'Kuzulama'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Yem'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Para'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Raporlar'),
        ],
      ),
    );
  }
}
