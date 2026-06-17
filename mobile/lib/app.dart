import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'providers/auth_providers.dart';

class RifqApp extends ConsumerWidget {
  const RifqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Keeps the push-notification subscription alive for the session.
    ref.watch(pushBootstrapProvider);
    return MaterialApp.router(
      title: AppConstants.appNameAr,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Force RTL Arabic throughout. Light mode only per spec.
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
