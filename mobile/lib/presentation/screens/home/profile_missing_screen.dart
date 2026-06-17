import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/repository_providers.dart';

/// Shown when a Firebase Auth user has no matching `/users/{uid}` doc.
///
/// This can happen if sign-up was interrupted between creating the auth
/// account and writing the Firestore profile. The recovery path is to sign
/// out so the user can restart the flow.
class ProfileMissingScreen extends ConsumerWidget {
  const ProfileMissingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'الحساب غير مكتمل',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لم نتمكن من العثور على ملفك الشخصي. سجّل خروجك ثم أعد المحاولة.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(authRepositoryProvider).signOut(),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
