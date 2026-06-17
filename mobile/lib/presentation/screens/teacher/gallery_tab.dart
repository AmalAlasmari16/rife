import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/media_item.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/teacher_providers.dart';
import '../../widgets/loading_view.dart';

/// Teacher-side gallery: thumbnail grid of the classroom's photos + upload
/// FAB. Long-press deletes.
class TeacherGalleryTab extends ConsumerStatefulWidget {
  const TeacherGalleryTab({super.key});

  @override
  ConsumerState<TeacherGalleryTab> createState() =>
      _TeacherGalleryTabState();
}

class _TeacherGalleryTabState extends ConsumerState<TeacherGalleryTab> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload({required MediaType type}) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null || user?.classroomId == null) return;

    final picked = type == MediaType.photo
        ? await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            imageQuality: 85,
          )
        : await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 2),
          );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(mediaRepositoryProvider).upload(
            file: File(picked.path),
            nurseryId: user!.nurseryId!,
            classroomId: user.classroomId!,
            uploadedByUid: user.id,
            type: type,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الوسائط')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الرفع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(teacherClassroomMediaProvider);
    return Scaffold(
      body: mediaAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (items) => _Grid(items: items),
      ),
      floatingActionButton: _UploadFab(
        uploading: _uploading,
        onPhoto: () => _pickAndUpload(type: MediaType.photo),
        onVideo: () => _pickAndUpload(type: MediaType.video),
      ),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.items});
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 56, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'لا توجد صور بعد. ابدأي بمشاركة لحظات اليوم.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _Tile(item: items[i]),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showPreview(context, item),
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('حذف'),
            content: const Text('سيتم حذف هذه الوسائط نهائياً.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(mediaRepositoryProvider).delete(
                nurseryId: item.nurseryId,
                item: item,
              );
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.thumbnailUrl ?? item.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.primaryLight,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          if (item.type == MediaType.video)
            const Positioned(
              right: 6,
              top: 6,
              child: Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 22),
            ),
          Positioned(
            left: 6,
            bottom: 4,
            child: Text(
              RifqDateUtils.time(item.createdAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(blurRadius: 2, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadFab extends StatelessWidget {
  const _UploadFab({
    required this.uploading,
    required this.onPhoto,
    required this.onVideo,
  });

  final bool uploading;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return const FloatingActionButton.extended(
        onPressed: null,
        icon: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
        label: Text('جارٍ الرفع…'),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined,
                      color: AppColors.primary),
                  title: const Text('صورة'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onPhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined,
                      color: AppColors.primary),
                  title: const Text('فيديو'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onVideo();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('إضافة'),
    );
  }
}

void _showPreview(BuildContext context, MediaItem item) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.thumbnailUrl ?? item.url,
              fit: BoxFit.contain,
            ),
          ),
          if (item.caption != null && item.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                item.caption!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    ),
  );
}
