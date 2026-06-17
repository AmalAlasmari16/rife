import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType {
  photo,
  video;

  String toFirestore() => name;

  static MediaType fromFirestore(String? raw) {
    return raw == 'video' ? MediaType.video : MediaType.photo;
  }
}

/// Metadata for an uploaded photo or video stored at
/// `/nurseries/{nurseryId}/media/{mediaId}`.
///
/// The binary itself lives in Cloud Storage under
/// `nurseries/{nurseryId}/classrooms/{classroomId}/{mediaId}.{ext}`.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.nurseryId,
    required this.classroomId,
    required this.url,
    required this.type,
    required this.uploadedByUid,
    required this.createdAt,
    this.caption,
    this.childIds = const [],
    this.thumbnailUrl,
  });

  final String id;
  final String nurseryId;
  final String classroomId;
  final String url;
  final MediaType type;
  final String uploadedByUid;
  final DateTime createdAt;
  final String? caption;

  /// Optional list of children featured in the media. Used by the parent
  /// gallery to filter to "just my child" view. Empty means "general
  /// classroom photo".
  final List<String> childIds;

  /// Used for video previews; null for photos.
  final String? thumbnailUrl;

  factory MediaItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return MediaItem(
      id: doc.id,
      nurseryId: (data['nurseryId'] as String?) ?? '',
      classroomId: (data['classroomId'] as String?) ?? '',
      url: (data['url'] as String?) ?? '',
      type: MediaType.fromFirestore(data['type'] as String?),
      uploadedByUid: (data['uploadedByUid'] as String?) ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      caption: data['caption'] as String?,
      childIds: ((data['childIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nurseryId': nurseryId,
        'classroomId': classroomId,
        'url': url,
        'type': type.toFirestore(),
        'uploadedByUid': uploadedByUid,
        'createdAt': createdAt.millisecondsSinceEpoch == 0
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
        'caption': caption,
        'childIds': childIds,
        'thumbnailUrl': thumbnailUrl,
      };
}
