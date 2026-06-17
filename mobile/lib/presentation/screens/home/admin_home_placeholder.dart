import 'package:flutter/material.dart';

import '_role_home_shell.dart';

class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'لوحة الحضانة',
      subtitle: 'لوحة مدير الحضانة',
      stepHint:
          'اختيار الخطة وصفحة الاشتراك تُبنى في المرحلة 3،\nثم الفصول والأطفال والموظفون في المرحلة 5.',
      icon: Icons.dashboard_rounded,
    );
  }
}
