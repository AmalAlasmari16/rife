import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus {
  unpaid,
  paid,
  overdue,
  cancelled;

  String get arabic {
    switch (this) {
      case InvoiceStatus.unpaid:
        return 'غير مدفوعة';
      case InvoiceStatus.paid:
        return 'مدفوعة';
      case InvoiceStatus.overdue:
        return 'متأخرة';
      case InvoiceStatus.cancelled:
        return 'ملغاة';
    }
  }

  String toFirestore() => name;
  static InvoiceStatus fromFirestore(String? raw) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => InvoiceStatus.unpaid,
    );
  }
}

enum PaymentMethod {
  mada,
  stcPay,
  bankTransfer,
  cash;

  String get arabic {
    switch (this) {
      case PaymentMethod.mada:
        return 'مدى';
      case PaymentMethod.stcPay:
        return 'STC Pay';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.cash:
        return 'نقدي';
    }
  }

  String toFirestore() => name;
  static PaymentMethod? fromFirestore(String? raw) {
    if (raw == null) return null;
    return PaymentMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => PaymentMethod.bankTransfer,
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.childId,
    required this.childName,
    required this.amount,
    required this.dueDate,
    required this.periodLabel,
    this.status = InvoiceStatus.unpaid,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String childName;
  final int amount;
  final DateTime dueDate;

  /// Human label like "أكتوبر 2025".
  final String periodLabel;

  final InvoiceStatus status;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;
  final String? notes;
  final DateTime? createdAt;

  bool get isOverdue =>
      status == InvoiceStatus.unpaid && DateTime.now().isAfter(dueDate);

  factory Invoice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Invoice(
      id: doc.id,
      childId: (data['childId'] as String?) ?? '',
      childName: (data['childName'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodLabel: (data['periodLabel'] as String?) ?? '',
      status: InvoiceStatus.fromFirestore(data['status'] as String?),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      paymentMethod:
          PaymentMethod.fromFirestore(data['paymentMethod'] as String?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'childName': childName,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'periodLabel': periodLabel,
        'status': status.toFirestore(),
        'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
        'paymentMethod': paymentMethod?.toFirestore(),
        'notes': notes,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Invoice copyWith({
    InvoiceStatus? status,
    DateTime? paidAt,
    PaymentMethod? paymentMethod,
    String? notes,
  }) {
    return Invoice(
      id: id,
      childId: childId,
      childName: childName,
      amount: amount,
      dueDate: dueDate,
      periodLabel: periodLabel,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
