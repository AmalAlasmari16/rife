import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_providers.dart';
import 'gallery_tab.dart';
import 'history_tab.dart';
import 'messages_tab.dart';
import 'parent_home_tab.dart';

class ParentShell extends ConsumerStatefulWidget {
  const ParentShell({super.key});

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  int _index = 0;

  Widget _body() {
    switch (_index) {
      case 1:
        return const HistoryTab();
      case 2:
        return const ParentGalleryTab();
      case 3:
        return const MessagesTab();
      case 0:
      default:
        return const ParentHomeTab();
    }
  }

  String _title() {
    switch (_index) {
      case 1:
        return 'الأرشيف';
      case 2:
        return 'الصور';
      case 3:
        return 'الرسائل';
      case 0:
      default:
        return 'طفلي';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title()),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_outlined),
            label: 'طفلي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'الأرشيف',
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
