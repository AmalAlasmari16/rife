/// Centralised Firestore collection / document path builders.
///
/// Keeping paths in one file makes it easier to enforce the multi-tenant
/// security rules: every nursery-scoped read or write goes through one of
/// these helpers.
class FirestorePaths {
  FirestorePaths._();

  // Top-level collections
  static const String nurseries = 'nurseries';
  static const String users = 'users';
  static const String messageThreads = 'messages';
  static const String platform = 'platform';

  // Nursery sub-collections
  static String nursery(String nurseryId) => '$nurseries/$nurseryId';
  static String classrooms(String nurseryId) =>
      '${nursery(nurseryId)}/classrooms';
  static String children(String nurseryId) => '${nursery(nurseryId)}/children';
  static String staff(String nurseryId) => '${nursery(nurseryId)}/staff';
  static String invoices(String nurseryId) => '${nursery(nurseryId)}/invoices';
  static String announcements(String nurseryId) =>
      '${nursery(nurseryId)}/announcements';
  static String dailyLogs(String nurseryId, String childId) =>
      '${nursery(nurseryId)}/children/$childId/dailyLogs';
  static String attendance(String nurseryId) =>
      '${nursery(nurseryId)}/attendance';
  static String media(String nurseryId) => '${nursery(nurseryId)}/media';

  // Platform stats (super admin)
  static const String platformStats = 'platform/stats';
}
