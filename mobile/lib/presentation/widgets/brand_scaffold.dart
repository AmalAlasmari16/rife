import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Scaffold used by auth screens — adds a back button, generous padding,
/// and a scrollable body so the keyboard never hides the submit button.
class BrandScaffold extends StatelessWidget {
  const BrandScaffold({
    super.key,
    required this.child,
    this.title,
    this.showBack = true,
  });

  final Widget child;
  final String? title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title == null && !showBack
          ? null
          : AppBar(
              automaticallyImplyLeading: showBack,
              title: title == null ? null : Text(title!),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: child,
        ),
      ),
    );
  }
}
