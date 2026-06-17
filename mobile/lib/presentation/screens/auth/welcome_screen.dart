import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../router/routes.dart';
import '../../widgets/rifq_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: RifqLogo(size: 110, onPrimary: true)),
              const SizedBox(height: 28),
              Text(
                AppConstants.appNameAr,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.tagline,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => context.push(Routes.registerAdmin),
                child: const Text('سجّل حضانتك'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () => context.push(Routes.inviteCode),
                child: const Text('لدي رمز دعوة'),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.push(Routes.publicEnrollment),
                child: const Text('تقديم طلب التحاق طفل'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => context.push(Routes.login),
                  child: const Text('لديك حساب؟ سجّل دخولك'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
