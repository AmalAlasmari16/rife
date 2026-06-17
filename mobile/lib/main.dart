import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/firebase_services/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait — matches the educator workflow (one-handed
  // attendance taps, parent feed scrolling).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Best-effort load of secrets. We don't fail the app if `.env` is missing
  // so QA builds still launch without a Gemini key.
  try {
    await dotenv.load();
  } catch (_) {
    // Silently ignore — Gemini-dependent screens will surface their own error.
  }

  await initializeDateFormatting('ar', null);
  await FirebaseBootstrap.init();

  runApp(const ProviderScope(child: RifqApp()));
}
