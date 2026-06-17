import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/child.dart';
import '../models/daily_log.dart';

/// Wraps the Gemini SDK so the rest of the app only sees a single
/// `generateDailyReport` call. The API key is loaded from `.env` at
/// startup; if it's missing the service throws [GeminiUnavailable] and the
/// UI falls back gracefully (the teacher can still write the report by hand).
class GeminiUnavailable implements Exception {
  const GeminiUnavailable(this.message);
  final String message;
  @override
  String toString() => 'GeminiUnavailable: $message';
}

class GeminiService {
  GeminiService();

  static const _systemPrompt =
      'أنت معلمة حضانة محترفة ومتفائلة. مهمتك كتابة تقرير يومي دافئ وإيجابي '
      'للوالدين عن طفلهم. التقرير يجب أن يكون بالعربية الفصحى البسيطة، '
      '3-4 جمل فقط، دافئ ومشجع، يذكر اسم الطفل، ويعطي الوالدين شعوراً '
      'بالطمأنينة والفخر.';

  GenerativeModel? _model;

  GenerativeModel _ensure() {
    if (_model != null) return _model!;
    final key = dotenv.maybeGet('GEMINI_API_KEY');
    if (key == null || key.isEmpty) {
      throw const GeminiUnavailable(
        'مفتاح Gemini غير مهيّأ. أضِفه إلى ملف .env كـ GEMINI_API_KEY.',
      );
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: key,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 220,
      ),
    );
    return _model!;
  }

  Future<String> generateDailyReport({
    required Child child,
    required DailyLog log,
    required bool present,
  }) async {
    final model = _ensure();
    final prompt = _buildUserMessage(
      child: child,
      log: log,
      present: present,
    );
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw const GeminiUnavailable('لم يتم استلام أي رد من النموذج.');
    }
    return text;
  }

  String _buildUserMessage({
    required Child child,
    required DailyLog log,
    required bool present,
  }) {
    final mealLines = log.meals.isEmpty
        ? 'لا توجد بيانات وجبات'
        : log.meals
            .map((m) => '${m.label}: ${m.amount.arabic}'
                '${m.notes == null ? "" : " (${m.notes})"}')
            .join('، ');

    final napLines = log.naps.isEmpty
        ? 'لم ينم'
        : log.naps
            .map((n) {
              final dur = n.duration;
              return dur == null
                  ? 'من الساعة ${_fmt(n.start)}'
                  : 'من ${_fmt(n.start)} إلى ${_fmt(n.end!)}'
                      ' (${dur.inMinutes} دقيقة)';
            })
            .join('، ');

    final activities =
        log.activities.isEmpty ? 'لا شيء' : log.activities.join('، ');
    final notes = log.teacherNotes ?? 'لا شيء';

    return '''
اسم الطفل: ${child.name}
الحضور: ${present ? "حاضر" : "غائب"}
الوجبة: $mealLines
النوم: $napLines
المزاج: ${log.mood?.arabic ?? "غير محدد"}
الأنشطة: $activities
ملاحظات: $notes
''';
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
