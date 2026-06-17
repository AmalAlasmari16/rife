import 'package:flutter/material.dart';

import '_role_home_shell.dart';

class TeacherHomePlaceholder extends StatelessWidget {
  const TeacherHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'صفي اليوم',
      subtitle: 'لوحة المعلمة',
      stepHint:
          'الحضور والتقرير اليومي والذكاء الاصطناعي يُبنى في المرحلة 6.',
      icon: Icons.school_rounded,
    );
  }
}
