import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../router/routes.dart';
import '../subscription/widgets/trial_banner.dart';
import 'today_tab.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _index = 0;

  Widget _body() {
    switch (_index) {
      case 1:
        return const _ComingSoon(
          icon: Icons.photo_library_outlined,
          title: 'الصور',
          subtitle: 'رفع صور الأنشطة يُبنى لاحقاً في هذه المرحلة.',
        );
      case 2:
        return const _ComingSoon(
          icon: Icons.forum_outlined,
          title: 'الرسائل',
          subtitle: 'المحادثات مع الأهالي تُبنى في المرحلة 7.',
        );
      case 0:
      default:
        return const TodayTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفي اليوم'),
        actions: [
          IconButton(
            tooltip: 'اشتراك الحضانة',
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => context.push(Routes.subscriptionManage),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            label: 'الحضور',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: 'الصور',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            label: 'الرسائل',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
