import 'package:flutter/material.dart';

import '../widgets/modern_ui.dart';
import 'dashboard_screen.dart';
import 'jobs_screen.dart';
import 'profile_screen.dart';
import 'resume_ai_screen.dart';
import 'tracker_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screenForIndex()),
      extendBody: true,
      bottomNavigationBar: _PillNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }

  Widget _screenForIndex() {
    switch (_index) {
      case 0:
        return const JobsScreen();
      case 1:
        return const ResumeAiScreen();
      case 2:
        return TrackerScreen(onBrowseJobs: () => setState(() => _index = 0));
      case 3:
        return const DashboardScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const JobsScreen();
    }
  }
}

class _PillNavigationBar extends StatelessWidget {
  const _PillNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    (label: 'Jobs', icon: Icons.work_outline, activeIcon: Icons.work),
    (
      label: 'Resume',
      icon: Icons.description_outlined,
      activeIcon: Icons.description
    ),
    (
      label: 'Tracker',
      icon: Icons.check_box_outlined,
      activeIcon: Icons.check_box
    ),
    (label: 'Dashboard', icon: Icons.bar_chart, activeIcon: Icons.bar_chart),
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: ModernColors.purple,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: ModernColors.purple.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = selectedIndex == index;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onDestinationSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: Colors.white,
                        size: selected ? 26 : 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
