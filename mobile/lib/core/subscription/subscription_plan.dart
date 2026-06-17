/// The three subscription tiers offered to nurseries.
///
/// All pricing is in Saudi Riyal (SAR) per month, and every plan includes
/// a 30-day free trial that grants full access regardless of tier.
enum SubscriptionPlan {
  basic,
  standard,
  premium;

  String get arabicName {
    switch (this) {
      case SubscriptionPlan.basic:
        return 'أساسي';
      case SubscriptionPlan.standard:
        return 'متوسط';
      case SubscriptionPlan.premium:
        return 'بريميوم';
    }
  }

  /// Monthly price in SAR.
  int get monthlyPrice {
    switch (this) {
      case SubscriptionPlan.basic:
        return 199;
      case SubscriptionPlan.standard:
        return 399;
      case SubscriptionPlan.premium:
        return 699;
    }
  }

  /// Hard child-count cap. `null` means unlimited.
  int? get maxChildren {
    switch (this) {
      case SubscriptionPlan.basic:
        return 30;
      case SubscriptionPlan.standard:
        return 80;
      case SubscriptionPlan.premium:
        return null;
    }
  }

  bool get hasBilling => this != SubscriptionPlan.basic;
  bool get hasAiReports => this != SubscriptionPlan.basic;
  bool get hasMultipleBranches => this == SubscriptionPlan.premium;
  bool get hasDedicatedSupport => this == SubscriptionPlan.premium;

  /// The Firestore string representation (matches the spec: Arabic names).
  String toFirestore() => arabicName;

  static SubscriptionPlan fromFirestore(String? raw) {
    switch (raw) {
      case 'متوسط':
        return SubscriptionPlan.standard;
      case 'بريميوم':
        return SubscriptionPlan.premium;
      case 'أساسي':
      default:
        return SubscriptionPlan.basic;
    }
  }
}

/// Lifecycle status of a nursery's subscription, mirroring Firestore.
enum SubscriptionStatus {
  trial,
  active,
  expired;

  String toFirestore() {
    switch (this) {
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
    }
  }

  static SubscriptionStatus fromFirestore(String? raw) {
    switch (raw) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
      default:
        return SubscriptionStatus.trial;
    }
  }
}
