import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/subscription/access_control.dart';
import '../../core/subscription/subscription_plan.dart';

/// Tenant document at `/nurseries/{nurseryId}`.
///
/// The subscription fields here are the source of truth for
/// [AccessControl]; everything else (children, classrooms, staff, ...)
/// lives in subcollections.
class Nursery {
  const Nursery({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.plan,
    required this.status,
    required this.trialStartDate,
    required this.trialActive,
    required this.childrenCount,
    this.logoUrl,
    this.licenseNumber,
    this.city,
    this.subscriptionExpiry,
    this.branchCount = 1,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime trialStartDate;
  final bool trialActive;
  final int childrenCount;
  final String? logoUrl;
  final String? licenseNumber;
  final String? city;
  final DateTime? subscriptionExpiry;
  final int branchCount;
  final DateTime? createdAt;

  SubscriptionSnapshot toSubscriptionSnapshot() => SubscriptionSnapshot(
        plan: plan,
        status: status,
        trialStartDate: trialStartDate,
        trialActive: trialActive,
        subscriptionExpiry: subscriptionExpiry,
        childrenCount: childrenCount,
      );

  factory Nursery.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Nursery(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      ownerUid: (data['ownerUid'] as String?) ?? '',
      plan: SubscriptionPlan.fromFirestore(data['plan'] as String?),
      status: SubscriptionStatus.fromFirestore(data['subscriptionStatus'] as String?),
      trialStartDate:
          (data['trialStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trialActive: (data['trialActive'] as bool?) ?? true,
      childrenCount: (data['childrenCount'] as num?)?.toInt() ?? 0,
      logoUrl: data['logoUrl'] as String?,
      licenseNumber: data['licenseNumber'] as String?,
      city: data['city'] as String?,
      subscriptionExpiry:
          (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      branchCount: (data['branchCount'] as num?)?.toInt() ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'ownerUid': ownerUid,
        'plan': plan.toFirestore(),
        'subscriptionStatus': status.toFirestore(),
        'trialStartDate': Timestamp.fromDate(trialStartDate),
        'trialActive': trialActive,
        'childrenCount': childrenCount,
        'logoUrl': logoUrl,
        'licenseNumber': licenseNumber,
        'city': city,
        'subscriptionExpiry': subscriptionExpiry == null
            ? null
            : Timestamp.fromDate(subscriptionExpiry!),
        'branchCount': branchCount,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
