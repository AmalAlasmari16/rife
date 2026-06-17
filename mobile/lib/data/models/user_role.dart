/// Roles in the multi-tenant system.
///
/// - [superAdmin]: platform owner, sees the SaaS dashboard across all
///   nurseries. There is no public signup path for this role; super-admin
///   accounts are provisioned manually.
/// - [admin]: nursery director/owner. Self-registers and becomes the
///   tenant administrator for a single nursery (or branch group, on
///   the بريميوم plan).
/// - [teacher]: classroom staff. Created via an invite issued by an admin.
/// - [parent]: guardian of one or more enrolled children. Created via an
///   invite issued by an admin.
enum UserRole {
  superAdmin,
  admin,
  teacher,
  parent;

  String get arabicName {
    switch (this) {
      case UserRole.superAdmin:
        return 'مالك المنصة';
      case UserRole.admin:
        return 'مدير الحضانة';
      case UserRole.teacher:
        return 'المعلمة';
      case UserRole.parent:
        return 'ولي الأمر';
    }
  }

  String toFirestore() {
    switch (this) {
      case UserRole.superAdmin:
        return 'superAdmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.parent:
        return 'parent';
    }
  }

  static UserRole fromFirestore(String? raw) {
    switch (raw) {
      case 'superAdmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
      default:
        return UserRole.parent;
    }
  }
}
