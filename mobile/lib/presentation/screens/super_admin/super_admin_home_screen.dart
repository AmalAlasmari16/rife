import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/nursery.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/platform_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';
import 'nursery_detail_sheet.dart';
import 'widgets/nursery_list_tile.dart';
import 'widgets/signups_chart.dart';
import 'widgets/stat_tile.dart';

/// Platform-owner dashboard. Reads every nursery in the system and computes
/// MRR, status counts, and a 6-month signup chart on the fly.
class SuperAdminHomeScreen extends ConsumerStatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  ConsumerState<SuperAdminHomeScreen> createState() =>
      _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState
    extends ConsumerState<SuperAdminHomeScreen> {
  String _query = '';
  SubscriptionStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(platformStatsProvider);
    final nurseriesAsync = ref.watch(allNurseriesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المنصة'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: nurseriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (nurseries) {
          final filtered = nurseries.where((n) {
            if (_filter != null && n.status != _filter) return false;
            if (_query.isEmpty) return true;
            return n.name.contains(_query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(allNurseriesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (stats != null) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      StatTile(
                        label: 'إجمالي الحضانات',
                        value: '${stats.totalNurseries}',
                        icon: Icons.business_outlined,
                      ),
                      StatTile(
                        label: 'الإيراد الشهري',
                        value: '${stats.monthlyRecurringRevenue}',
                        suffix: 'ريال',
                        icon: Icons.payments_outlined,
                        tint: AppColors.success,
                      ),
                      StatTile(
                        label: 'في التجربة',
                        value: '${stats.trialCount}',
                        icon: Icons.celebration_outlined,
                        tint: AppColors.accent,
                      ),
                      StatTile(
                        label: 'مشتركون',
                        value: '${stats.activeCount}',
                        icon: Icons.verified_outlined,
                        tint: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SignupsChart(byMonth: stats.signupsByMonth),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Text(
                      'الحضانات',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم الحضانة',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _filter == null,
                      onSelected: () => setState(() => _filter = null),
                    ),
                    _FilterChip(
                      label: 'تجربة',
                      selected: _filter == SubscriptionStatus.trial,
                      onSelected: () => setState(
                        () => _filter = SubscriptionStatus.trial,
                      ),
                    ),
                    _FilterChip(
                      label: 'مشترك',
                      selected: _filter == SubscriptionStatus.active,
                      onSelected: () => setState(
                        () => _filter = SubscriptionStatus.active,
                      ),
                    ),
                    _FilterChip(
                      label: 'منتهٍ',
                      selected: _filter == SubscriptionStatus.expired,
                      onSelected: () => setState(
                        () => _filter = SubscriptionStatus.expired,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'لا توجد حضانات مطابقة',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final n in filtered) ...[
                    NurseryListTile(
                      nursery: n,
                      onTap: () =>
                          NurseryDetailSheet.show(context, n),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
