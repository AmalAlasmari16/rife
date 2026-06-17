import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/invoice.dart';
import '../../../providers/invoice_providers.dart';
import '../../widgets/loading_view.dart';

class ParentInvoicesScreen extends ConsumerWidget {
  const ParentInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(selectedChildInvoicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body: invoicesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(
              child: Text('لا توجد فواتير حالياً',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          final unpaid = invoices
              .where((i) =>
                  i.status == InvoiceStatus.unpaid ||
                  i.status == InvoiceStatus.overdue)
              .fold<int>(0, (a, b) => a + b.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: unpaid > 0
                      ? AppColors.danger.withOpacity(0.08)
                      : AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      unpaid > 0
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      color: unpaid > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unpaid > 0
                            ? 'لديك مستحقات: $unpaid ريال'
                            : 'جميع الفواتير مدفوعة',
                        style: TextStyle(
                          color: unpaid > 0
                              ? AppColors.danger
                              : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final i in invoices) ...[
                _Tile(invoice: i),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.invoice});
  final Invoice invoice;

  Color _color() {
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

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.periodLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.status == InvoiceStatus.paid && invoice.paidAt != null
                      ? 'دُفعت ${RifqDateUtils.shortDate(invoice.paidAt!)}'
                          '${invoice.paymentMethod == null ? "" : " · ${invoice.paymentMethod!.arabic}"}'
                      : 'تستحق ${RifqDateUtils.shortDate(invoice.dueDate)}',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  invoice.isOverdue && invoice.status == InvoiceStatus.unpaid
                      ? 'متأخرة'
                      : invoice.status.arabic,
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
    );
  }
}
