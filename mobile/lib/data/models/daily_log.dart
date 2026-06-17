import 'package:cloud_firestore/cloud_firestore.dart';

enum MealAmount {
  full,
  half,
  none;

  String get arabic {
    switch (this) {
      case MealAmount.full:
        return 'كل';
      case MealAmount.half:
        return 'نصف';
      case MealAmount.none:
        return 'لم يأكل';
    }
  }

  String toFirestore() => name;

  static MealAmount fromFirestore(String? raw) {
    return MealAmount.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => MealAmount.full,
    );
  }
}

enum Mood {
  happy,
  calm,
  tired,
  sad,
  upset;

  String get emoji {
    switch (this) {
      case Mood.happy:
        return '😊';
      case Mood.calm:
        return '🙂';
      case Mood.tired:
        return '😴';
      case Mood.sad:
        return '😔';
      case Mood.upset:
        return '😢';
    }
  }

  String get arabic {
    switch (this) {
      case Mood.happy:
        return 'سعيد';
      case Mood.calm:
        return 'هادئ';
      case Mood.tired:
        return 'متعب';
      case Mood.sad:
        return 'حزين';
      case Mood.upset:
        return 'منزعج';
    }
  }

  String toFirestore() => name;

  static Mood? fromFirestore(String? raw) {
    if (raw == null) return null;
    return Mood.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => Mood.calm,
    );
  }
}

class Meal {
  const Meal({required this.label, required this.amount, this.notes});

  /// 'إفطار' / 'غداء' / 'وجبة خفيفة' / custom
  final String label;
  final MealAmount amount;
  final String? notes;

  Map<String, dynamic> toMap() => {
        'label': label,
        'amount': amount.toFirestore(),
        'notes': notes,
      };

  factory Meal.fromMap(Map<String, dynamic> m) {
    return Meal(
      label: (m['label'] as String?) ?? '',
      amount: MealAmount.fromFirestore(m['amount'] as String?),
      notes: m['notes'] as String?,
    );
  }
}

class Nap {
  const Nap({required this.start, this.end});
  final DateTime start;
  final DateTime? end;

  Duration? get duration => end == null ? null : end!.difference(start);

  Map<String, dynamic> toMap() => {
        'start': Timestamp.fromDate(start),
        'end': end == null ? null : Timestamp.fromDate(end!),
      };

  factory Nap.fromMap(Map<String, dynamic> m) {
    return Nap(
      start: (m['start'] as Timestamp).toDate(),
      end: (m['end'] as Timestamp?)?.toDate(),
    );
  }
}

/// A child's daily log for a single day. Stored at
/// `/nurseries/{nid}/children/{childId}/dailyLogs/{YYYY-MM-DD}`.
class DailyLog {
  const DailyLog({
    required this.date,
    required this.childId,
    this.meals = const [],
    this.naps = const [],
    this.mood,
    this.bathroomNotes,
    this.activities = const [],
    this.incidents = const [],
    this.teacherNotes,
    this.aiReport,
    this.editedReport,
    this.sentAt,
  });

  final DateTime date;
  final String childId;
  final List<Meal> meals;
  final List<Nap> naps;
  final Mood? mood;
  final String? bathroomNotes;
  final List<String> activities;
  final List<String> incidents;
  final String? teacherNotes;

  /// Original AI-generated report (kept for reference even after editing).
  final String? aiReport;

  /// Edited report — this is what's actually shown to parents.
  final String? editedReport;

  /// When the teacher tapped "send to parents".
  final DateTime? sentAt;

  String? get reportForParent => editedReport ?? aiReport;

  static String docId(DateTime date) {
    return '${date.year.toString().padLeft(4, "0")}-'
        '${date.month.toString().padLeft(2, "0")}-'
        '${date.day.toString().padLeft(2, "0")}';
  }

  factory DailyLog.empty({required String childId, required DateTime date}) {
    return DailyLog(
      childId: childId,
      date: DateTime(date.year, date.month, date.day),
    );
  }

  factory DailyLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String childId,
    required DateTime fallbackDate,
  }) {
    final data = doc.data() ?? const {};
    return DailyLog(
      childId: (data['childId'] as String?) ?? childId,
      date: (data['date'] as Timestamp?)?.toDate() ?? fallbackDate,
      meals: ((data['meals'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Meal.fromMap(m.cast<String, dynamic>()))
          .toList(),
      naps: ((data['naps'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Nap.fromMap(m.cast<String, dynamic>()))
          .toList(),
      mood: Mood.fromFirestore(data['mood'] as String?),
      bathroomNotes: data['bathroomNotes'] as String?,
      activities: ((data['activities'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      incidents: ((data['incidents'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      teacherNotes: data['teacherNotes'] as String?,
      aiReport: data['aiReport'] as String?,
      editedReport: data['editedReport'] as String?,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'date': Timestamp.fromDate(date),
        'meals': meals.map((m) => m.toMap()).toList(),
        'naps': naps.map((n) => n.toMap()).toList(),
        'mood': mood?.toFirestore(),
        'bathroomNotes': bathroomNotes,
        'activities': activities,
        'incidents': incidents,
        'teacherNotes': teacherNotes,
        'aiReport': aiReport,
        'editedReport': editedReport,
        'sentAt': sentAt == null ? null : Timestamp.fromDate(sentAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  DailyLog copyWith({
    List<Meal>? meals,
    List<Nap>? naps,
    Mood? mood,
    String? bathroomNotes,
    List<String>? activities,
    List<String>? incidents,
    String? teacherNotes,
    String? aiReport,
    String? editedReport,
    DateTime? sentAt,
  }) {
    return DailyLog(
      date: date,
      childId: childId,
      meals: meals ?? this.meals,
      naps: naps ?? this.naps,
      mood: mood ?? this.mood,
      bathroomNotes: bathroomNotes ?? this.bathroomNotes,
      activities: activities ?? this.activities,
      incidents: incidents ?? this.incidents,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      aiReport: aiReport ?? this.aiReport,
      editedReport: editedReport ?? this.editedReport,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
