import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../providers/auth_providers.dart';
import '../screens/auth/invite_code_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_otp_screen.dart';
import '../screens/auth/register_admin_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/admin_home_placeholder.dart';
import '../screens/home/parent_home_placeholder.dart';
import '../screens/home/profile_missing_screen.dart';
import '../screens/home/super_admin_home_placeholder.dart';
import '../screens/home/teacher_home_placeholder.dart';
import '../screens/splash_screen.dart';
import 'routes.dart';

/// Refresh the router whenever a provider value changes. go_router rebuilds
/// the redirect chain on each notify, so any auth-state shift triggers a
/// re-evaluation.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerRefreshProvider = Provider<_RouterRefresh>(_RouterRefresh.new);

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);

      // Wait for auth to settle before redirecting.
      if (authState.isLoading) return null;

      final firebaseUser = authState.valueOrNull;
      final location = state.matchedLocation;

      final isOnAuthRoute = location == Routes.welcome ||
          location == Routes.login ||
          location == Routes.registerAdmin ||
          location == Routes.inviteCode ||
          location == Routes.phoneOtp ||
          location == Routes.splash;

      // Signed-out → push them to the welcome screen.
      if (firebaseUser == null) {
        return isOnAuthRoute && location != Routes.splash
            ? null
            : Routes.welcome;
      }

      // Signed-in but the Firestore profile is still loading — keep them on
      // the splash so we don't flicker through wrong routes.
      if (userAsync.isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final appUser = userAsync.valueOrNull;
      if (appUser == null) {
        // Auth user exists but no `/users/{uid}` doc — happens briefly during
        // sign-up, or permanently if onboarding was interrupted.
        return location == Routes.profileMissing
            ? null
            : Routes.profileMissing;
      }

      final target = switch (appUser.role) {
        UserRole.superAdmin => Routes.superAdminHome,
        UserRole.admin => Routes.adminHome,
        UserRole.teacher => Routes.teacherHome,
        UserRole.parent => Routes.parentHome,
      };

      // Push past the splash + any auth screens to the role home.
      if (isOnAuthRoute || location == Routes.profileMissing) {
        return target;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.registerAdmin,
        builder: (_, __) => const RegisterAdminScreen(),
      ),
      GoRoute(
        path: Routes.inviteCode,
        builder: (_, __) => const InviteCodeScreen(),
      ),
      GoRoute(
        path: Routes.phoneOtp,
        builder: (_, state) {
          final args = state.extra as PhoneOtpArgs?;
          return PhoneOtpScreen(args: args ?? const PhoneOtpArgs());
        },
      ),
      GoRoute(
        path: Routes.superAdminHome,
        builder: (_, __) => const SuperAdminHomePlaceholder(),
      ),
      GoRoute(
        path: Routes.adminHome,
        builder: (_, __) => const AdminHomePlaceholder(),
      ),
      GoRoute(
        path: Routes.teacherHome,
        builder: (_, __) => const TeacherHomePlaceholder(),
      ),
      GoRoute(
        path: Routes.parentHome,
        builder: (_, __) => const ParentHomePlaceholder(),
      ),
      GoRoute(
        path: Routes.profileMissing,
        builder: (_, __) => const ProfileMissingScreen(),
      ),
    ],
  );
});
