import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../parent/messages_tab.dart';
import '../subscription/widgets/trial_banner.dart';
import 'check_in_screen.dart';
import 'gallery_tab.dart';
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
        return const CheckInScreen();
      case 2:
        return const TeacherGalleryTab();
      case 3:
        return const MessagesTab();
      case 0:
      default:
        return const TodayTab();
    }
  }

  bool get _isImmersive => _index == 1 || _index == 2;

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
            tooltip: 'حسابي',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: _isImmersive
          ? _body()
          : Column(
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
            icon: Icon(Icons.qr_code_scanner_outlined),
            label: 'الباب',
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
