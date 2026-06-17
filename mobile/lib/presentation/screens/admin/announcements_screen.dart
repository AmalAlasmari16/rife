import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/announcement.dart';
import '../../../data/models/classroom.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';

/// Admin-side: compose and review announcements. Composer is opened as a
/// modal sheet from the FAB.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('إعلان جديد'),
        onPressed: () => _openComposer(context, ref),
      ),
      body: announcements.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AnnouncementTile(item: list[i]),
          );
        },
      ),
    );
  }

  Future<void> _openComposer(BuildContext context, WidgetRef ref) async {
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    final authorUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (nurseryId == null || authorUid == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ComposerSheet(
        nurseryId: nurseryId,
        authorUid: authorUid,
      ),
    );
  }
}

class _AnnouncementTile extends ConsumerWidget {
  const _AnnouncementTile({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref
          .read(announcementRepositoryProvider)
          .delete(nurseryId: item.nurseryId, announcementId: item.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.accentLight,
                  child: Icon(Icons.campaign_outlined,
                      color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  RifqDateUtils.shortDate(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.body),
            const SizedBox(height: 6),
            Text(
              item.isNurseryWide
                  ? 'لجميع الأهالي'
                  : 'فصل محدد',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'لم يتم نشر أي إعلان بعد',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet({
    required this.nurseryId,
    required this.authorUid,
  });

  final String nurseryId;
  final String authorUid;

  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Classroom? _classroom;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(announcementRepositoryProvider).post(
            nurseryId: widget.nurseryId,
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            authorUid: widget.authorUid,
            classroomId: _classroom?.id,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classrooms = ref.watch(classroomsProvider).valueOrNull ?? const [];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'إعلان جديد',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'اكتب عنواناً قصيراً'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'النص'),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'اكتب نص الإعلان'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'الجمهور',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('كل الأهالي'),
                      selected: _classroom == null,
                      onSelected: (_) =>
                          setState(() => _classroom = null),
                    ),
                    for (final c in classrooms)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _classroom?.id == c.id,
                        onSelected: (_) =>
                            setState(() => _classroom = c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_outlined),
                  label: _busy
                      ? const Text('جارٍ الإرسال…')
                      : const Text('نشر'),
                  onPressed: _busy ? null : _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
