import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initSupabase();

  final dsn = dotenv.env['SENTRY_DSN'];
  if (dsn != null && dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.2; // 트랜잭션 샘플링
        options.environment = dotenv.env['DATA_SOURCE'] ?? 'unknown';
      },
      appRunner: () =>
          runApp(const ProviderScope(child: GangnamBosalApp())),
    );
  } else {
    // Sentry DSN 미설정 (dev 환경) — 일반 실행
    runApp(const ProviderScope(child: GangnamBosalApp()));
  }
}
