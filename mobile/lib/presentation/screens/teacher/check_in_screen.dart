import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/child.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/teacher_providers.dart';

/// Scanner-driven check-in / check-out. The QR payload is the canonical
/// `rifq://{nurseryId}/{childId}` produced by [ChildQrCard]. We toggle the
/// child's status: not-yet-here → present, present → picked.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null, orElse: () => null);
    if (raw == null) return;

    final now = DateTime.now();
    if (now.difference(_lastScanAt) < const Duration(seconds: 2)) return;
    _lastScanAt = now;

    final parsed = _parsePayload(raw);
    if (parsed == null) {
      setState(() => _lastResult = 'رمز غير صالح');
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    if (parsed.nurseryId != user!.nurseryId) {
      setState(() => _lastResult = 'هذا الرمز ليس من حضانتك');
      return;
    }

    final children = ref.read(childrenProvider).valueOrNull ?? const [];
    final child = children.where((c) => c.id == parsed.childId).firstOrNull;
    if (child == null) {
      setState(() => _lastResult = 'الطفل غير مسجّل');
      return;
    }

    final attendance =
        ref.read(todayAttendanceProvider).valueOrNull;
    final current = attendance?.statuses[child.id];
    final repo = ref.read(attendanceRepositoryProvider);
    final date = ref.read(todayProvider);

    final bool checkingIn = current != AttendanceStatus.present;
    if (checkingIn) {
      await repo.recordCheckIn(
        nurseryId: user.nurseryId!,
        date: date,
        childId: child.id,
      );
    } else {
      await repo.recordCheckOut(
        nurseryId: user.nurseryId!,
        date: date,
        childId: child.id,
      );
    }
    if (!mounted) return;
    setState(() {
      _lastResult =
          '${checkingIn ? "تم تسجيل دخول" : "تم تسجيل خروج"} ${child.name}';
    });
  }

  _Payload? _parsePayload(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'rifq') return null;
    final segments = [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];
    if (segments.length < 2) return null;
    return _Payload(nurseryId: segments[0], childId: segments[1]);
  }

  @override
  Widget build(BuildContext context) {
    final children =
        ref.watch(childrenProvider).valueOrNull ?? const <Child>[];
    final attendance =
        ref.watch(todayAttendanceProvider).valueOrNull;
    final staff = ref.watch(staffProvider).valueOrNull ?? const [];

    final presentCount = attendance == null
        ? 0
        : attendance.statuses.values
            .where((s) =>
                s == AttendanceStatus.present || s == AttendanceStatus.late)
            .length;
    final ratio = staff.isEmpty
        ? '—'
        : '${presentCount}:${staff.length}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('الدخول والخروج'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'الفلاش',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'تبديل الكاميرا',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'نسبة الإشراف: $ratio  ·  حاضرون $presentCount',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_lastResult != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastResult!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (children.isNotEmpty)
                          TextButton(
                            onPressed: () => _showManual(context, children),
                            child: const Text('يدوي'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pin_outlined),
                    label: const Text('إدخال يدوي'),
                    onPressed: () => _showManual(context, children),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showManual(BuildContext context, List<Child> children) async {
    final picked = await showModalBottomSheet<Child>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManualPicker(children: children),
    );
    if (picked == null) return;
    final attendance =
        ref.read(todayAttendanceProvider).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    final current = attendance?.statuses[picked.id];
    final repo = ref.read(attendanceRepositoryProvider);
    final date = ref.read(todayProvider);
    final checkingIn = current != AttendanceStatus.present;
    if (checkingIn) {
      await repo.recordCheckIn(
        nurseryId: user!.nurseryId!,
        date: date,
        childId: picked.id,
      );
    } else {
      await repo.recordCheckOut(
        nurseryId: user!.nurseryId!,
        date: date,
        childId: picked.id,
      );
    }
    if (!mounted) return;
    setState(() {
      _lastResult =
          '${checkingIn ? "تم تسجيل دخول" : "تم تسجيل خروج"} ${picked.name} '
          '(${RifqDateUtils.time(DateTime.now())})';
    });
  }
}

class _Payload {
  const _Payload({required this.nurseryId, required this.childId});
  final String nurseryId;
  final String childId;
}

class _ManualPicker extends StatelessWidget {
  const _ManualPicker({required this.children});
  final List<Child> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر الطفل',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: children.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = children[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.child_care,
                          color: AppColors.primary),
                    ),
                    title: Text(c.name),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
