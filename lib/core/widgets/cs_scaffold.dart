import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';

/// Campus Signal — Shell Scaffold with Bottom Navigation
///
/// Wraps the main tab screens and provides persistent bottom navigation.
/// Each destination uses a semantically correct icon + label.
class CSShellScaffold extends StatelessWidget {
  const CSShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      body: navigationShell,
      bottomNavigationBar: _CSBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _CSBottomNav extends StatelessWidget {
  const _CSBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CSColors.graphiteHairline, width: 0.5),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
            tooltip: 'Home — discover items',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Explore',
            tooltip: 'Explore — item map',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
            tooltip: 'My Activity — your reports and claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
            tooltip: 'Profile — account and settings',
          ),
        ],
      ),
    );
  }
}
