import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Date helpers used across the app. Hijri formatting is included because
/// parents can switch their calendar preference to Hijri.
class RifqDateUtils {
  RifqDateUtils._();

  static String formatGregorianArabic(DateTime date) {
    return DateFormat('EEEE d MMMM y', 'ar').format(date);
  }

  static String formatHijri(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    return '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
  }

  static String shortDate(DateTime date) =>
      DateFormat('yyyy/MM/dd').format(date);

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }
}
