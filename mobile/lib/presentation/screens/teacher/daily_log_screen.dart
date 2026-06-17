import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/access_control.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/child.dart';
import '../../../data/models/daily_log.dart';
import '../../../data/services/gemini_service.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../../../providers/teacher_providers.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/subscription_gate.dart';

/// Daily-log editor for a single child. The form is fully bound to a
/// [DailyLog] value held in local state; writes go through the repository's
/// merge-set so partial saves never lose data.
class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key, required this.child});

  final Child child;

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  late DailyLog _log;
  final _notesCtrl = TextEditingController();
  final _bathroomCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _generating = false;
  String? _aiError;

  static const _activityOptions = <String>[
    'لعب خارجي',
    'فنون وأعمال يدوية',
    'قراءة',
    'موسيقى',
    'أنشطة حركية',
    'تعلّم',
    'لعب جماعي',
  ];

  static const _mealLabels = <String>[
    'إفطار',
    'وجبة خفيفة صباحاً',
    'غداء',
    'وجبة خفيفة عصراً',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _bathroomCtrl.dispose();
    _reportCtrl.dispose();
    super.dispose();
  }

  void _syncFromStream(DailyLog log) {
    _log = log;
    if (!_loaded) {
      _notesCtrl.text = log.teacherNotes ?? '';
      _bathroomCtrl.text = log.bathroomNotes ?? '';
      _reportCtrl.text = log.reportForParent ?? '';
      _loaded = true;
    }
  }

  Future<void> _save({Map<String, dynamic>? overlay}) async {
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;
    setState(() => _saving = true);
    try {
      final updated = _log.copyWith(
        teacherNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        bathroomNotes: _bathroomCtrl.text.trim().isEmpty
            ? null
            : _bathroomCtrl.text.trim(),
        editedReport: _reportCtrl.text.trim().isEmpty
            ? null
            : _reportCtrl.text.trim(),
      );
      _log = updated;
      await ref
          .read(dailyLogRepositoryProvider)
          .save(nurseryId: nurseryId, log: updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateAiReport() async {
    setState(() {
      _generating = true;
      _aiError = null;
    });
    try {
      final attendance =
          ref.read(todayAttendanceProvider).valueOrNull?.statuses;
      final present = (attendance?[widget.child.id] ?? AttendanceStatus.absent) !=
          AttendanceStatus.absent;
      final text = await ref.read(geminiServiceProvider).generateDailyReport(
            child: widget.child,
            log: _log,
            present: present,
          );
      _reportCtrl.text = text;
      _log = _log.copyWith(aiReport: text, editedReport: text);
      await _save();
    } on GeminiUnavailable catch (e) {
      setState(() => _aiError = e.message);
    } catch (e) {
      setState(() => _aiError = 'تعذّر توليد التقرير. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _sendToParent() async {
    if (_reportCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب التقرير قبل الإرسال')),
      );
      return;
    }
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;
    setState(() => _saving = true);
    final updated = _log.copyWith(
      editedReport: _reportCtrl.text.trim(),
      sentAt: DateTime.now(),
    );
    _log = updated;
    await ref
        .read(dailyLogRepositoryProvider)
        .save(nurseryId: nurseryId, log: updated);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التقرير لولي الأمر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(childDailyLogProvider(widget.child.id));
    final textTheme = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child.name),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saving ? null : () => _save(),
          ),
        ],
      ),
      body: logAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (log) {
          _syncFromStream(log);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                RifqDateUtils.formatGregorianArabic(today),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle('المزاج'),
              _MoodPicker(
                value: _log.mood,
                onChanged: (m) => setState(() => _log = _log.copyWith(mood: m)),
              ),
              const SizedBox(height: 20),
              _SectionTitle('الوجبات'),
              _MealEditor(
                meals: _log.meals,
                onChanged: (ms) =>
                    setState(() => _log = _log.copyWith(meals: ms)),
                presetLabels: _mealLabels,
              ),
              const SizedBox(height: 20),
              _SectionTitle('النوم'),
              _NapEditor(
                naps: _log.naps,
                onChanged: (ns) =>
                    setState(() => _log = _log.copyWith(naps: ns)),
              ),
              const SizedBox(height: 20),
              _SectionTitle('الحمام / الحفّاضات'),
              TextField(
                controller: _bathroomCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'مثل: ٣ حفاضات، ذهب للحمام ٢ مرات',
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle('الأنشطة'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _activityOptions)
                    FilterChip(
                      label: Text(a),
                      selected: _log.activities.contains(a),
                      onSelected: (sel) {
                        final next = [..._log.activities];
                        sel ? next.add(a) : next.remove(a);
                        setState(() => _log = _log.copyWith(activities: next));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle('حوادث / ملاحظات مهمة'),
              _IncidentEditor(
                incidents: _log.incidents,
                onChanged: (xs) =>
                    setState(() => _log = _log.copyWith(incidents: xs)),
              ),
              const SizedBox(height: 20),
              _SectionTitle('ملاحظات المعلمة'),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'ملاحظات إضافية للسجل الداخلي',
                ),
              ),
              const SizedBox(height: 24),
              _AiSection(
                error: _aiError,
                busy: _generating,
                onGenerate: _generateAiReport,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reportCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'التقرير المرسل لولي الأمر',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _sendToParent,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  _log.sentAt == null
                      ? 'إرسال إلى ولي الأمر'
                      : 'إعادة الإرسال (آخر مرة ${RifqDateUtils.time(_log.sentAt!)})',
                ),
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.value, required this.onChanged});
  final Mood? value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in Mood.values)
          ChoiceChip(
            label: Text('${m.emoji}  ${m.arabic}'),
            selected: value == m,
            onSelected: (_) => onChanged(m),
          ),
      ],
    );
  }
}

class _MealEditor extends StatelessWidget {
  const _MealEditor({
    required this.meals,
    required this.onChanged,
    required this.presetLabels,
  });

  final List<Meal> meals;
  final ValueChanged<List<Meal>> onChanged;
  final List<String> presetLabels;

  @override
  Widget build(BuildContext context) {
    final byLabel = {for (final m in meals) m.label: m};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in presetLabels) ...[
          Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final amount in MealAmount.values)
                      ChoiceChip(
                        label: Text(amount.arabic),
                        selected: byLabel[label]?.amount == amount,
                        onSelected: (_) {
                          final next = [
                            for (final m in meals)
                              if (m.label != label) m,
                            Meal(label: label, amount: amount),
                          ];
                          onChanged(next);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NapEditor extends StatelessWidget {
  const _NapEditor({required this.naps, required this.onChanged});
  final List<Nap> naps;
  final ValueChanged<List<Nap>> onChanged;

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(context: context, initialTime: initial);
  }

  DateTime _withTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < naps.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTime(
                      context,
                      TimeOfDay.fromDateTime(naps[i].start),
                    );
                    if (picked == null) return;
                    final next = [...naps];
                    next[i] = Nap(start: _withTime(picked), end: naps[i].end);
                    onChanged(next);
                  },
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text(
                    'من ${naps[i].start.hour.toString().padLeft(2, "0")}:'
                    '${naps[i].start.minute.toString().padLeft(2, "0")}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickTime(
                      context,
                      TimeOfDay.fromDateTime(naps[i].end ?? naps[i].start),
                    );
                    if (picked == null) return;
                    final next = [...naps];
                    next[i] = Nap(start: naps[i].start, end: _withTime(picked));
                    onChanged(next);
                  },
                  icon: const Icon(Icons.alarm_outlined),
                  label: Text(
                    naps[i].end == null
                        ? 'إلى --:--'
                        : 'إلى ${naps[i].end!.hour.toString().padLeft(2, "0")}:'
                            '${naps[i].end!.minute.toString().padLeft(2, "0")}',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.danger),
                onPressed: () {
                  final next = [...naps]..removeAt(i);
                  onChanged(next);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextButton.icon(
          onPressed: () {
            final now = DateTime.now();
            onChanged([
              ...naps,
              Nap(start: DateTime(now.year, now.month, now.day, 13, 0)),
            ]);
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة فترة نوم'),
        ),
      ],
    );
  }
}

class _IncidentEditor extends StatelessWidget {
  const _IncidentEditor({required this.incidents, required this.onChanged});
  final List<String> incidents;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final inc in incidents)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(inc)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(
                    [for (final i in incidents) if (i != inc) i],
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'اكتب وصف الحادثة',
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  onChanged([...incidents, v.trim()]);
                  ctrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                onChanged([...incidents, ctrl.text.trim()]);
                ctrl.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AiSection extends StatelessWidget {
  const _AiSection({
    required this.error,
    required this.busy,
    required this.onGenerate,
  });

  final String? error;
  final bool busy;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SubscriptionGate(
      require: (ac) => ac.canUseAiReports,
      denied: const UpgradePrompt(
        feature: 'تقارير الذكاء الاصطناعي',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'الذكاء الاصطناعي',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'دع رِفق يصيغ تقريراً دافئاً للأهل من بيانات اليوم. يمكنك تعديله قبل الإرسال.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: busy ? null : onGenerate,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('توليد التقرير بالذكاء الاصطناعي'),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
