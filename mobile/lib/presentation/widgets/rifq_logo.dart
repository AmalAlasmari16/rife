import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Wordmark mark used on auth screens. Pure text until the brand asset
/// is dropped into `assets/logo/`.
class RifqLogo extends StatelessWidget {
  const RifqLogo({super.key, this.size = 96, this.onPrimary = false});

  final double size;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final fg = onPrimary ? AppColors.primary : AppColors.primary;
    final bg = onPrimary ? Colors.white : AppColors.primaryLight;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Text(
        AppConstants.appNameAr,
        style: TextStyle(
          color: fg,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
