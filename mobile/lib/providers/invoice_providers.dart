import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/invoice.dart';
import 'auth_providers.dart';
import 'parent_providers.dart';
import 'repository_providers.dart';

final nurseryInvoicesProvider =
    StreamProvider<List<Invoice>>((ref) async* {
  final nurseryId =
      ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(invoiceRepositoryProvider).watchAll(nurseryId);
});

final selectedChildInvoicesProvider =
    StreamProvider<List<Invoice>>((ref) async* {
  final nurseryId =
      ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  final childId = ref.watch(selectedChildIdProvider);
  if (nurseryId == null || childId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(invoiceRepositoryProvider).watchForChild(
        nurseryId: nurseryId,
        childId: childId,
      );
});
