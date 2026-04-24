import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_bosals.dart';
import '../models/bosal.dart';
import '../models/operating_hours.dart';

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

  // ---- owner/admin write paths (guarded by RLS + SECURITY DEFINER RPCs) ----

  /// 보살 본인이 수정 가능한 필드만 업데이트. null 인자는 "변경 없음".
  Future<Bosal> updateOwnerFields({
    required String bosalId,
    String? name,
    String? oneLiner,
    String? description,
    int? experienceYears,
    String? consultStyleCode,
    String? phoneDisplay,
    String? phoneE164,
    int? originalPrice,
    int? discountedPrice,
    int? firstVisitPrice,
    int? maxPoints,
    String? sido,
    String? sigungu,
    String? eupmyeondong,
    String? roadAddress,
    String? jibunAddress,
    String? postalCode,
    String? regionCode,
    String? subRegionCode,
    double? latitude,
    double? longitude,
  });

  /// 특징 리스트 일괄 교체.
  Future<List<String>> replaceFeatures(String bosalId, List<String> labels);

  /// 카테고리 M:N 일괄 교체 (category codes).
  Future<List<String>> replaceCategories(String bosalId, List<String> codes);

  /// 운영 시간 일괄 교체. [entries]는 `OperatingHours` 리스트.
  Future<List<OperatingHours>> replaceOperatingHours(
    String bosalId,
    List<OperatingHours> entries,
  );

  /// 공개 여부 토글.
  Future<void> publish(String bosalId, bool isPublished);
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

  @override
  Future<Bosal> updateOwnerFields({
    required String bosalId,
    String? name,
    String? oneLiner,
    String? description,
    int? experienceYears,
    String? consultStyleCode,
    String? phoneDisplay,
    String? phoneE164,
    int? originalPrice,
    int? discountedPrice,
    int? firstVisitPrice,
    int? maxPoints,
    String? sido,
    String? sigungu,
    String? eupmyeondong,
    String? roadAddress,
    String? jibunAddress,
    String? postalCode,
    String? regionCode,
    String? subRegionCode,
    double? latitude,
    double? longitude,
  }) async {
    throw UnsupportedError('Mock data source는 쓰기 경로를 지원하지 않습니다.');
  }

  @override
  Future<List<String>> replaceFeatures(String bosalId, List<String> labels) async {
    throw UnsupportedError('Mock');
  }

  @override
  Future<List<String>> replaceCategories(String bosalId, List<String> codes) async {
    throw UnsupportedError('Mock');
  }

  @override
  Future<List<OperatingHours>> replaceOperatingHours(
    String bosalId,
    List<OperatingHours> entries,
  ) async {
    throw UnsupportedError('Mock');
  }

  @override
  Future<void> publish(String bosalId, bool isPublished) async {
    throw UnsupportedError('Mock');
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

  @override
  Future<Bosal> updateOwnerFields({
    required String bosalId,
    String? name,
    String? oneLiner,
    String? description,
    int? experienceYears,
    String? consultStyleCode,
    String? phoneDisplay,
    String? phoneE164,
    int? originalPrice,
    int? discountedPrice,
    int? firstVisitPrice,
    int? maxPoints,
    String? sido,
    String? sigungu,
    String? eupmyeondong,
    String? roadAddress,
    String? jibunAddress,
    String? postalCode,
    String? regionCode,
    String? subRegionCode,
    double? latitude,
    double? longitude,
  }) async {
    await _client.rpc('update_bosal_owner_fields', params: {
      'p_bosal_id': bosalId,
      if (name != null) 'p_name': name,
      if (oneLiner != null) 'p_one_liner': oneLiner,
      if (description != null) 'p_description': description,
      if (experienceYears != null) 'p_experience_years': experienceYears,
      if (consultStyleCode != null) 'p_consult_style': consultStyleCode,
      if (phoneDisplay != null) 'p_phone_display': phoneDisplay,
      if (phoneE164 != null) 'p_phone_e164': phoneE164,
      if (originalPrice != null) 'p_original_price': originalPrice,
      if (discountedPrice != null) 'p_discounted_price': discountedPrice,
      if (firstVisitPrice != null) 'p_first_visit_price': firstVisitPrice,
      if (maxPoints != null) 'p_max_points': maxPoints,
      if (sido != null) 'p_sido': sido,
      if (sigungu != null) 'p_sigungu': sigungu,
      if (eupmyeondong != null) 'p_eupmyeondong': eupmyeondong,
      if (roadAddress != null) 'p_road_address': roadAddress,
      if (jibunAddress != null) 'p_jibun_address': jibunAddress,
      if (postalCode != null) 'p_postal_code': postalCode,
      if (regionCode != null) 'p_region_code': regionCode,
      if (subRegionCode != null) 'p_sub_region_code': subRegionCode,
      if (latitude != null) 'p_latitude': latitude,
      if (longitude != null) 'p_longitude': longitude,
    });
    final fresh = await byId(bosalId);
    if (fresh == null) {
      throw StateError('bosal not found after update: $bosalId');
    }
    return fresh;
  }

  @override
  Future<List<String>> replaceFeatures(String bosalId, List<String> labels) async {
    final rows = await _client.rpc('replace_bosal_features', params: {
      'p_bosal_id': bosalId,
      'p_labels': labels,
    });
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => r['label'] as String)
        .toList();
  }

  @override
  Future<List<String>> replaceCategories(String bosalId, List<String> codes) async {
    await _client.rpc('replace_bosal_categories', params: {
      'p_bosal_id': bosalId,
      'p_category_codes': codes,
    });
    return codes;
  }

  @override
  Future<List<OperatingHours>> replaceOperatingHours(
    String bosalId,
    List<OperatingHours> entries,
  ) async {
    final payload = entries
        .map((e) => {
              'weekday': e.weekday,
              'opens_at': e.opensAt,
              'closes_at': e.closesAt,
              'break_start': e.breakStart,
              'break_end': e.breakEnd,
              'note': e.note,
            })
        .toList();
    final rows = await _client.rpc('replace_operating_hours', params: {
      'p_bosal_id': bosalId,
      'p_entries': payload,
    });
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(OperatingHours.fromMap)
        .toList();
  }

  @override
  Future<void> publish(String bosalId, bool isPublished) async {
    await _client.rpc('publish_bosal_profile', params: {
      'p_bosal_id': bosalId,
      'p_is_published': isPublished,
    });
  }
}
