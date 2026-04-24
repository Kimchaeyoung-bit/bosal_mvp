import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_bosals.dart';
import '../models/bosal.dart';

/// 보살 조회용 필터. UI 계층에서 구성해 data source 에 전달.
class BosalFilter {
  /// 선택된 sub-region 코드 (예: 'gangnam'). 비면 region 필터 없음.
  final List<String> subRegionIds;

  /// 카테고리 코드. null 또는 'all' 이면 무필터.
  final String? categoryId;

  /// 이름/소개/특징/상담 스타일에서 부분 일치 검색.
  final String? query;

  const BosalFilter({
    this.subRegionIds = const [],
    this.categoryId,
    this.query,
  });

  bool get isEmpty =>
      subRegionIds.isEmpty &&
      (categoryId == null || categoryId == 'all') &&
      (query == null || query!.trim().isEmpty);
}

abstract class BosalDataSource {
  Future<List<Bosal>> list({BosalFilter filter});
  Future<Bosal?> byId(String id);
}

// ================================================================
// Mock
// ================================================================
class MockBosalDataSource implements BosalDataSource {
  @override
  Future<List<Bosal>> list({BosalFilter filter = const BosalFilter()}) async {
    var result = List<Bosal>.from(mockBosals);

    if (filter.subRegionIds.isNotEmpty) {
      final ids = filter.subRegionIds.toSet();
      result = result
          .where((b) => b.subRegionIds.any(ids.contains))
          .toList(growable: false);
    }

    if (filter.categoryId != null && filter.categoryId != 'all') {
      result = result
          .where((b) => b.categoryIds.contains(filter.categoryId))
          .toList(growable: false);
    }

    final q = filter.query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      result = result.where((b) {
        if (b.name.toLowerCase().contains(q)) return true;
        if (b.consultStyle.toLowerCase().contains(q)) return true;
        if ((b.description ?? '').toLowerCase().contains(q)) return true;
        if (b.features.any((f) => f.toLowerCase().contains(q))) return true;
        return false;
      }).toList(growable: false);
    }

    return result;
  }

  @override
  Future<Bosal?> byId(String id) async {
    try {
      return mockBosals.firstWhere((b) => b.id == id);
    } on StateError {
      return null;
    }
  }
}

// ================================================================
// Supabase
// ================================================================
class SupabaseBosalDataSource implements BosalDataSource {
  SupabaseBosalDataSource(this._client);
  final SupabaseClient _client;

  /// Nested select spec for full aggregate hydration.
  /// Keep this as a single source of truth so list()/byId() share the shape.
  static const _selectSpec =
      '*,'
      'consult_styles(code,label),'
      'ad_intent_tiers(code,label),'
      'region:regions(code,name),'
      'sub_region:sub_regions(code,name),'
      'bosal_images(url,kind,sort_order),'
      'bosal_features(label,sort_order),'
      'bosal_categories(category:categories(code)),'
      'operating_hours(weekday,opens_at,closes_at,break_start,break_end,note)';

  @override
  Future<List<Bosal>> list({BosalFilter filter = const BosalFilter()}) async {
    var query = _client
        .from('bosals')
        .select(_selectSpec)
        .eq('is_published', true);

    if (filter.subRegionIds.isNotEmpty) {
      // sub_region stored as single FK in current schema; filter by IN.
      // When schema evolves to M:N, switch to an RPC.
      query = query.inFilter('sub_region.code', filter.subRegionIds);
    }

    if (filter.categoryId != null && filter.categoryId != 'all') {
      // M:N through bosal_categories; easiest via RPC or view. Temporary approach:
      // filter client-side after fetch if needed. For server-side, we'd create a view.
      // Here we use inFilter on the joined path.
      query = query.eq('bosal_categories.category.code', filter.categoryId!);
    }

    final q = filter.query?.trim();
    if (q != null && q.isNotEmpty) {
      final pattern = '%$q%';
      query = query.or(
        'name.ilike.$pattern,'
        'one_liner.ilike.$pattern,'
        'description.ilike.$pattern',
      );
    }

    final rows = await query.order('rating_avg', ascending: false);
    return rows.cast<Map<String, dynamic>>().map(Bosal.fromMap).toList();
  }

  @override
  Future<Bosal?> byId(String id) async {
    final rows = await _client
        .from('bosals')
        .select(_selectSpec)
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    return Bosal.fromMap(rows.first);
  }
}
