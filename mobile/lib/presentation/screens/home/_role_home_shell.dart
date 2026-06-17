import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';

/// Shared chrome for the four role homes during early build steps. Provides
/// the AppBar, sign-out, and a "this lands in step N" stub body. Real bottom
/// navigation comes in later steps when each role's tabs are designed.
class RoleHomeShell extends ConsumerWidget {
  const RoleHomeShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stepHint,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String stepHint;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryLight,
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                user == null ? subtitle : 'مرحباً ${user.name}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (user != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.role.arabicName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                stepHint,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience for screens that want to show the role label.
extension UserRoleColors on UserRole {
  Color get tint {
    switch (this) {
      case UserRole.superAdmin:
        return AppColors.accent;
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.teacher:
        return AppColors.info;
      case UserRole.parent:
        return AppColors.success;
    }
  }
}
