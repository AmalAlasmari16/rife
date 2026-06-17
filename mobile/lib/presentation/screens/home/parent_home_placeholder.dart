import 'package:flutter/material.dart';

import '_role_home_shell.dart';

class ParentHomePlaceholder extends StatelessWidget {
  const ParentHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomeShell(
      title: 'طفلي',
      subtitle: 'صفحة ولي الأمر',
      stepHint: 'يوميات الطفل والصور والرسائل تُبنى في المرحلة 7.',
      icon: Icons.child_care_rounded,
    );
  }
}
