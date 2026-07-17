import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';

/// App shell with bottom navigation bar.
/// Wraps the main tab screens (Dashboard, Members, Donors, Projects, News).
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    '/dashboard',
    '/members',
    '/donors',
    '/projects',
    '/news',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndex();
  }

  void _updateIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      context.go(_tabs[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: isAdminAsync.when(
              data: (isAdmin) => _buildBottomNav(isAdmin),
              loading: () => _buildBottomNav(false),
              error: (_, __) => _buildBottomNav(false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Members',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.volunteer_activism_outlined),
        activeIcon: Icon(Icons.volunteer_activism),
        label: 'Donors',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        activeIcon: Icon(Icons.folder),
        label: 'Projects',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.newspaper_outlined),
        activeIcon: Icon(Icons.newspaper),
        label: 'News',
      ),
    ];

    return BottomNavigationBar(
      currentIndex: _currentIndex.clamp(0, items.length - 1),
      onTap: _onTabTapped,
      items: items,
    );
  }
}
