// lib/widgets/app_navigation.dart
// No errors — outputting as confirmed-clean file.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundPrimary,
        border: Border(
          top: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 60,
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        animationDuration: const Duration(milliseconds: 250),
        destinations: [
          _dest(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _dest(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart_rounded,
            label: 'Stats',
          ),
          _dest(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  NavigationDestination _dest({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppTheme.textDisabled, size: 20),
      selectedIcon: Icon(selectedIcon, color: AppTheme.accent, size: 20),
      label: label,
    );
  }
}