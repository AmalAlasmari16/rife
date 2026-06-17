import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/invoice.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/subscription_gate.dart';
import '../super_admin/widgets/stat_tile.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفوترة')),
      body: SubscriptionGate(
        require: (ac) => ac.canUseBilling,
        denied: const Padding(
          padding: EdgeInsets.all(20),
          child: UpgradePrompt(feature: 'الفوترة'),
        ),
        child: const _BillingBody(),
      ),
      floatingActionButton: SubscriptionGate(
        require: (ac) => ac.canUseBilling,
        denied: const SizedBox.shrink(),
        child: const GenerateInvoicesAction(),
      ),
    );
  }
}

class _BillingBody extends ConsumerWidget {
  const _BillingBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(nurseryInvoicesProvider);
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];

    return invoicesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (invoices) {
        final totalUnpaid = invoices
            .where((i) =>
                i.status == InvoiceStatus.unpaid ||
                i.status == InvoiceStatus.overdue)
            .fold<int>(0, (a, b) => a + b.amount);
        final totalPaid = invoices
            .where((i) => i.status == InvoiceStatus.paid)
            .fold<int>(0, (a, b) => a + b.amount);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'مستحقات',
                      value: '$totalUnpaid',
                      suffix: 'ريال',
                      icon: Icons.pending_outlined,
                      tint: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      label: 'محصلات',
                      value: '$totalPaid',
                      suffix: 'ريال',
                      icon: Icons.payments_outlined,
                      tint: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: invoices.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _InvoiceTile(
                        invoice: invoices[i],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لم يتم إصدار أي فاتورة بعد',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'اضغط على "إصدار فواتير شهرية" أدناه',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTile extends ConsumerWidget {
  const _InvoiceTile({required this.invoice});
  final Invoice invoice;

  Color _statusColor() {
    if (invoice.isOverdue) return AppColors.danger;
    switch (invoice.status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.unpaid:
        return AppColors.warning;
      case InvoiceStatus.overdue:
        return AppColors.danger;
      case InvoiceStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  String _statusLabel() {
    if (invoice.isOverdue && invoice.status == InvoiceStatus.unpaid) {
      return 'متأخرة';
    }
    return invoice.status.arabic;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openActions(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.receipt_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.childName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoice.periodLabel} · '
                      'تستحق ${RifqDateUtils.shortDate(invoice.dueDate)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.amount} ريال',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    final repo = ref.read(invoiceRepositoryProvider);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'فاتورة ${invoice.childName}',
                textAlign: TextAlign.center,
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
              ),
              const SizedBox(height: 12),
              if (invoice.status != InvoiceStatus.paid) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'سجّل الدفع كـ:',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                for (final m in PaymentMethod.values)
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: Text(m.arabic),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await repo.markPaid(
                        nurseryId: user!.nurseryId!,
                        invoiceId: invoice.id,
                        method: m,
                      );
                    },
                  ),
              ] else
                ListTile(
                  leading: const Icon(Icons.undo, color: AppColors.warning),
                  title: const Text('إلغاء الدفع'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await repo.markUnpaid(
                      nurseryId: user!.nurseryId!,
                      invoiceId: invoice.id,
                    );
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('حذف الفاتورة',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await repo.delete(
                    nurseryId: user!.nurseryId!,
                    invoiceId: invoice.id,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAB action — generate invoices for all enrolled children for next month.
class GenerateInvoicesAction extends ConsumerWidget {
  const GenerateInvoicesAction({super.key});

  static const _monthNames = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.add_card_outlined),
      label: const Text('إصدار فواتير شهرية'),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final children = ref.read(childrenProvider).valueOrNull ?? const [];
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد أطفال لإصدار فواتيرهم')),
      );
      return;
    }
    final amountCtrl = TextEditingController(text: '500');
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 5);
    final periodLabel = '${_monthNames[next.month - 1]} ${next.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إصدار فواتير $periodLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سيتم إصدار فاتورة لكل من ${children.length} طفلاً.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ لكل طفل (ريال)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إصدار'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;

    final created =
        await ref.read(invoiceRepositoryProvider).generateMonthlyBatch(
              nurseryId: user!.nurseryId!,
              children: children,
              amount: amount,
              dueDate: next,
              periodLabel: periodLabel,
            );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إصدار $created فاتورة')),
    );
  }
}
