import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL 또는 SUPABASE_ANON_KEY가 .env에 설정되지 않았습니다.',
    );
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
}

SupabaseClient get supabase => Supabase.instance.client;
