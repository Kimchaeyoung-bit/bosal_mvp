import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_regions.dart';
import '../models/region.dart';

abstract class RegionDataSource {
  Future<List<Region>> list();
}

class MockRegionDataSource implements RegionDataSource {
  @override
  Future<List<Region>> list() async => List<Region>.from(mockRegions);
}

class SupabaseRegionDataSource implements RegionDataSource {
  SupabaseRegionDataSource(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Region>> list() async {
    final rows = await _client
        .from('regions')
        .select(
          'code,name,sort_order,'
          'sub_regions(code,name,sort_order,latitude,longitude)',
        )
        .order('sort_order');
    return rows.cast<Map<String, dynamic>>().map(Region.fromMap).toList();
  }
}
