import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/media_item.dart';
import '../../../providers/parent_providers.dart';
import '../../widgets/loading_view.dart';

/// Parent-side photo/video gallery for the selected child's classroom.
class ParentGalleryTab extends ConsumerWidget {
  const ParentGalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(parentChildMediaProvider);
    return mediaAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (items) {
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
                    'لا توجد صور بعد. ستظهر هنا فور مشاركتها من المعلمة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _Tile(item: items[i]),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreview(context, item),
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
              RifqDateUtils.shortDate(item.createdAt),
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
