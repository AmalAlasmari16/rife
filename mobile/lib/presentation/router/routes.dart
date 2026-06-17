/// Named-route constants. Keeping them in one file means `go(...)` calls
/// across the app stay typo-safe.
class Routes {
  Routes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const registerAdmin = '/register-admin';
  static const inviteCode = '/invite';
  static const phoneOtp = '/phone-otp';

  static const superAdminHome = '/super-admin';
  static const adminHome = '/admin';
  static const teacherHome = '/teacher';
  static const parentHome = '/parent';

  /// Catch-all shown when the signed-in user has no Firestore profile yet.
  static const profileMissing = '/profile-missing';
}
