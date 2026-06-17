import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../providers/auth_providers.dart';
import '../../providers/subscription_providers.dart';
import '../screens/auth/invite_code_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_otp_screen.dart';
import '../screens/auth/register_admin_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/home/parent_home_placeholder.dart';
import '../screens/home/profile_missing_screen.dart';
import '../screens/super_admin/super_admin_home_screen.dart';
import '../screens/teacher/teacher_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/subscription/paywall_screen.dart';
import '../screens/subscription/plan_selection_screen.dart';
import '../screens/subscription/subscription_manage_screen.dart';
import 'routes.dart';

/// Refresh the router whenever a provider value changes. go_router rebuilds
/// the redirect chain on each notify, so any auth or subscription shift
/// triggers a re-evaluation.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
    ref.listen(currentNurseryProvider, (_, __) => notifyListeners());
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

      if (authState.isLoading) return null;

      final firebaseUser = authState.valueOrNull;
      final location = state.matchedLocation;

      const authRoutes = {
        Routes.welcome,
        Routes.login,
        Routes.registerAdmin,
        Routes.inviteCode,
        Routes.phoneOtp,
        Routes.splash,
      };
      final isOnAuthRoute = authRoutes.contains(location);

      // Signed-out → push them to the welcome screen.
      if (firebaseUser == null) {
        return isOnAuthRoute && location != Routes.splash
            ? null
            : Routes.welcome;
      }

      // Signed-in but the Firestore profile is still loading.
      if (userAsync.isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final appUser = userAsync.valueOrNull;
      if (appUser == null) {
        return location == Routes.profileMissing
            ? null
            : Routes.profileMissing;
      }

      final roleHome = switch (appUser.role) {
        UserRole.superAdmin => Routes.superAdminHome,
        UserRole.admin => Routes.adminHome,
        UserRole.teacher => Routes.teacherHome,
        UserRole.parent => Routes.parentHome,
      };

      // ---- Subscription gating (admin/teacher/parent — super-admin is
      // platform-wide and never blocked).
      if (appUser.role != UserRole.superAdmin) {
        final nurseryAsync = ref.read(currentNurseryProvider);
        if (nurseryAsync.isLoading) {
          return location == Routes.splash ? null : Routes.splash;
        }
        final nursery = nurseryAsync.valueOrNull;

        if (nursery != null) {
          // Admin who just registered hasn't picked a plan yet — push into
          // the onboarding screen before anything else.
          if (appUser.role == UserRole.admin &&
              nursery.planSelectedAt == null) {
            if (location == Routes.planSelection) return null;
            return Routes.planSelection;
          }

          final ac = ref.read(accessControlProvider);
          if (ac != null && !ac.hasAnyAccess) {
            // Hard paywall — only paywall + subscription-manage are reachable.
            if (location == Routes.paywall ||
                location == Routes.subscriptionManage) {
              return null;
            }
            return Routes.paywall;
          }
        }
      }

      // Push past splash / auth screens to the role home.
      if (isOnAuthRoute || location == Routes.profileMissing) {
        return roleHome;
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
        builder: (_, __) => const SuperAdminHomeScreen(),
      ),
      GoRoute(
        path: Routes.adminHome,
        builder: (_, __) => const AdminShell(),
      ),
      GoRoute(
        path: Routes.teacherHome,
        builder: (_, __) => const TeacherShell(),
      ),
      GoRoute(
        path: Routes.parentHome,
        builder: (_, __) => const ParentHomePlaceholder(),
      ),
      GoRoute(
        path: Routes.profileMissing,
        builder: (_, __) => const ProfileMissingScreen(),
      ),
      GoRoute(
        path: Routes.planSelection,
        builder: (_, __) => const PlanSelectionScreen(),
      ),
      GoRoute(
        path: Routes.paywall,
        builder: (_, __) => const PaywallScreen(),
      ),
      GoRoute(
        path: Routes.subscriptionManage,
        builder: (_, __) => const SubscriptionManageScreen(),
      ),
    ],
  );
});
