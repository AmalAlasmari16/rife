import 'package:flutter/material.dart';

import '_role_home_shell.dart';

class SuperAdminHomePlaceholder extends StatelessWidget {
  const SuperAdminHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'لوحة المنصة',
      subtitle: 'لوحة مالك المنصة',
      stepHint: 'لوحة الإيرادات والاشتراكات تُبنى في المرحلة 4.',
      icon: Icons.insights_rounded,
    );
  }
}
