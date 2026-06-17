import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../subscription/widgets/trial_banner.dart';
import 'children_tab.dart';
import 'classrooms_tab.dart';
import 'home_tab.dart';
import 'staff_tab.dart';

/// Bottom-nav container for the nursery admin role.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _tabs = <_TabSpec>[
    _TabSpec(label: 'الرئيسية', icon: Icons.home_outlined),
    _TabSpec(label: 'الأطفال', icon: Icons.child_care_outlined),
    _TabSpec(label: 'الفصول', icon: Icons.meeting_room_outlined),
    _TabSpec(label: 'الموظفون', icon: Icons.badge_outlined),
  ];

  Widget _body() {
    switch (_index) {
      case 1:
        return const ChildrenTab();
      case 2:
        return const ClassroomsTab();
      case 3:
        return const StaffTab();
      case 0:
      default:
        return const AdminHomeTab();
    }
  }

  String _title() => _tabs[_index].label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title()),
        actions: [
          IconButton(
            tooltip: 'اشتراكي',
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => context.push(Routes.subscriptionManage),
          ),
          IconButton(
            tooltip: 'حسابي',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          const TrialBanner(),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final t in _tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
