import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/child.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  InvoiceRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String nurseryId) =>
      _db.collection(FirestorePaths.invoices(nurseryId));

  Stream<List<Invoice>> watchAll(String nurseryId) {
    return _col(nurseryId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Invoice.fromFirestore).toList());
  }

  Stream<List<Invoice>> watchForChild({
    required String nurseryId,
    required String childId,
  }) {
    return _col(nurseryId)
        .where('childId', isEqualTo: childId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Invoice.fromFirestore).toList());
  }

  Future<Invoice> create({
    required String nurseryId,
    required Child child,
    required int amount,
    required DateTime dueDate,
    required String periodLabel,
    String? notes,
  }) async {
    final ref = _col(nurseryId).doc();
    final invoice = Invoice(
      id: ref.id,
      childId: child.id,
      childName: child.name,
      amount: amount,
      dueDate: dueDate,
      periodLabel: periodLabel,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await ref.set(invoice.toFirestore());
    return invoice;
  }

  /// Issue one invoice per active child for the upcoming month, skipping any
  /// child that already has an invoice tagged with the same [periodLabel].
  Future<int> generateMonthlyBatch({
    required String nurseryId,
    required List<Child> children,
    required int amount,
    required DateTime dueDate,
    required String periodLabel,
  }) async {
    final existing = await _col(nurseryId)
        .where('periodLabel', isEqualTo: periodLabel)
        .get();
    final issuedChildIds = existing.docs
        .map((d) => (d.data()['childId'] as String?) ?? '')
        .toSet();

    final batch = _db.batch();
    var count = 0;
    for (final c in children) {
      if (issuedChildIds.contains(c.id)) continue;
      final ref = _col(nurseryId).doc();
      final invoice = Invoice(
        id: ref.id,
        childId: c.id,
        childName: c.name,
        amount: amount,
        dueDate: dueDate,
        periodLabel: periodLabel,
        createdAt: DateTime.now(),
      );
      batch.set(ref, invoice.toFirestore());
      count++;
    }
    if (count > 0) await batch.commit();
    return count;
  }

  Future<void> markPaid({
    required String nurseryId,
    required String invoiceId,
    required PaymentMethod method,
  }) {
    return _col(nurseryId).doc(invoiceId).update({
      'status': InvoiceStatus.paid.toFirestore(),
      'paidAt': FieldValue.serverTimestamp(),
      'paymentMethod': method.toFirestore(),
    });
  }

  Future<void> markUnpaid({
    required String nurseryId,
    required String invoiceId,
  }) {
    return _col(nurseryId).doc(invoiceId).update({
      'status': InvoiceStatus.unpaid.toFirestore(),
      'paidAt': null,
      'paymentMethod': null,
    });
  }

  Future<void> delete({
    required String nurseryId,
    required String invoiceId,
  }) {
    return _col(nurseryId).doc(invoiceId).delete();
  }
}
