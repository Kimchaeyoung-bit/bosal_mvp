import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/banner_ad.dart';

abstract class BannerAdDataSource {
  Future<List<BannerAd>> listActive({AdPlacement placement = AdPlacement.homeTop});
}

class MockBannerAdDataSource implements BannerAdDataSource {
  @override
  Future<List<BannerAd>> listActive({
    AdPlacement placement = AdPlacement.homeTop,
  }) async =>
      const [];
}

class SupabaseBannerAdDataSource implements BannerAdDataSource {
  SupabaseBannerAdDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<List<BannerAd>> listActive({
    AdPlacement placement = AdPlacement.homeTop,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('banner_ads')
        .select()
        .eq('placement', placement.dbValue)
        .eq('is_active', true)
        .lte('start_at', now)
        .gte('end_at', now)
        .order('weight', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(BannerAd.fromMap).toList();
  }
}
