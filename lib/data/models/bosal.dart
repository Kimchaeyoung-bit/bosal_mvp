import 'operating_hours.dart';

/// 보살 프로필 aggregate.
///
/// DB 스키마([supabase/migrations/20260424000300_bosals.sql])의 `bosals` 테이블과
/// 관련 자식 테이블(`bosal_images`, `bosal_features`, `bosal_categories`,
/// `operating_hours`, 조인 룩업)을 하나의 모델로 표현한다.
///
/// 기존 UI 호환을 위해 필드 이름을 최대한 보존했으며, DB 이행 후
/// 새로 추가된 필드(address/광고 의향/운영시간 등)는 nullable default로 받는다.
class Bosal {
  // identity
  final String id;
  final String? slug;
  final String name;
  final String? oneLiner;           // DB: one_liner (줄 소개)
  final String? description;

  // professional
  final int experienceYears;
  final String consultStyle;        // label from consult_styles lookup
  final String? consultStyleCode;

  // contact
  final String? phoneNumber;        // display form (010-1234-5678)
  final String? phoneE164;          // +821012345678

  // pricing
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final int firstVisitPrice;
  final int maxPoints;

  // address (structured)
  final String? sido;
  final String? sigungu;
  final String? eupmyeondong;
  final String? roadAddress;
  final String? jibunAddress;
  final String? postalCode;
  final String regionId;            // region code ('seoul')
  final List<String> subRegionIds;  // sub_region codes ['gangnam','seolleung']
  final double? latitude;
  final double? longitude;

  // classification
  final List<String> categoryIds;   // category codes
  final List<String> features;      // label strings, ordered

  // advertising
  final String? adIntentTierCode;   // 'none' | 'interested' | 'active_campaign'

  // images
  final String? profileImageUrl;
  final List<String> galleryImageUrls;

  // operating hours (per weekday, 0=Sun..6=Sat)
  final List<OperatingHours> operatingHours;

  // denormalized counters
  final double rating;              // DB: rating_avg
  final int reviewCount;
  final int qnaCount;
  final int callCount;
  final int reservationButtonCount;
  final int consultRequests;        // DB: consult_request_count

  // meta
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const Bosal({
    required this.id,
    this.slug,
    required this.name,
    this.oneLiner,
    this.description,
    this.experienceYears = 0,
    required this.consultStyle,
    this.consultStyleCode,
    this.phoneNumber,
    this.phoneE164,
    this.originalPrice = 0,
    this.discountedPrice = 0,
    this.discountPercent = 0,
    this.firstVisitPrice = 0,
    this.maxPoints = 0,
    this.sido,
    this.sigungu,
    this.eupmyeondong,
    this.roadAddress,
    this.jibunAddress,
    this.postalCode,
    required this.regionId,
    this.subRegionIds = const [],
    this.latitude,
    this.longitude,
    this.categoryIds = const [],
    this.features = const [],
    this.adIntentTierCode,
    this.profileImageUrl,
    this.galleryImageUrls = const [],
    this.operatingHours = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.qnaCount = 0,
    this.callCount = 0,
    this.reservationButtonCount = 0,
    this.consultRequests = 0,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// 전체 주소 표시용 (구조화 주소 → 한 줄).
  String? get addressDisplay {
    if (roadAddress != null && roadAddress!.isNotEmpty) return roadAddress;
    final parts = <String>[
      if (sido != null && sido!.isNotEmpty) sido!,
      if (sigungu != null && sigungu!.isNotEmpty) sigungu!,
      if (eupmyeondong != null && eupmyeondong!.isNotEmpty) eupmyeondong!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  /// PostgREST nested-select 결과를 파싱해 Bosal 인스턴스를 생성한다.
  ///
  /// 기대하는 쿼리 형태 (한 예):
  /// ```
  /// select=*,
  ///   consult_styles(code,label),
  ///   ad_intent_tiers(code),
  ///   region:regions(code),
  ///   bosal_images(url,kind,sort_order),
  ///   bosal_features(label,sort_order),
  ///   bosal_categories(category:categories(code)),
  ///   operating_hours(*)
  /// ```
  factory Bosal.fromMap(Map<String, dynamic> m) {
    // consult_styles (joined row or null)
    final style = m['consult_styles'] as Map<String, dynamic>?;
    final styleLabel = style?['label'] as String? ?? '';
    final styleCode = style?['code'] as String?;

    // ad_intent_tiers
    final adTier = m['ad_intent_tiers'] as Map<String, dynamic>?;
    final adTierCode = adTier?['code'] as String?;

    // region
    final region = m['region'] as Map<String, dynamic>?;
    final regionCode = region?['code'] as String? ?? (m['region_code'] as String? ?? '');

    // sub_regions: accept either a single joined sub-region or an array through a junction
    // (current schema has sub_region_id single; but we model list for future flexibility)
    final subRegionCodes = <String>[];
    final subRegionJoin = m['sub_region'] as Map<String, dynamic>?;
    if (subRegionJoin != null) {
      final code = subRegionJoin['code'] as String?;
      if (code != null) subRegionCodes.add(code);
    }

    // images (sorted by sort_order)
    final imagesRaw = (m['bosal_images'] as List?) ?? const [];
    final imageMaps = imagesRaw
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => (a['sort_order'] as int? ?? 0)
          .compareTo(b['sort_order'] as int? ?? 0));
    String? profileImage;
    final gallery = <String>[];
    for (final im in imageMaps) {
      final url = im['url'] as String?;
      if (url == null) continue;
      final kind = im['kind'] as String?;
      if (profileImage == null && (kind == 'profile' || kind == null)) {
        profileImage = url;
      } else {
        gallery.add(url);
      }
    }

    // features
    final featuresRaw = (m['bosal_features'] as List?) ?? const [];
    final featureMaps = featuresRaw
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => (a['sort_order'] as int? ?? 0)
          .compareTo(b['sort_order'] as int? ?? 0));
    final features = featureMaps
        .map((e) => e['label'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    // categories (M:N through bosal_categories)
    final catsRaw = (m['bosal_categories'] as List?) ?? const [];
    final categoryIds = catsRaw
        .cast<Map<String, dynamic>>()
        .map((r) => (r['category'] as Map<String, dynamic>?)?['code'] as String?)
        .whereType<String>()
        .toList(growable: false);

    // operating_hours
    final ohRaw = (m['operating_hours'] as List?) ?? const [];
    final operatingHoursList = ohRaw
        .cast<Map<String, dynamic>>()
        .map(OperatingHours.fromMap)
        .toList(growable: false)
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    // location (Supabase returns geography as WKB hex or GeoJSON depending on view;
    // here we prefer explicit latitude/longitude columns if present in `metadata`
    // or selected via a computed view. For now, read from top-level keys.)
    double? lat = (m['latitude'] as num?)?.toDouble();
    double? lng = (m['longitude'] as num?)?.toDouble();
    // Fallback: if a `location` GeoJSON is present.
    if ((lat == null || lng == null) && m['location'] is Map) {
      final loc = m['location'] as Map;
      final coords = loc['coordinates'] as List?;
      if (coords != null && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return Bosal(
      id: m['id'] as String,
      slug: m['slug'] as String?,
      name: m['name'] as String,
      oneLiner: m['one_liner'] as String?,
      description: m['description'] as String?,
      experienceYears: (m['experience_years'] as num?)?.toInt() ?? 0,
      consultStyle: styleLabel,
      consultStyleCode: styleCode,
      phoneNumber: m['phone_display'] as String?,
      phoneE164: m['phone_e164'] as String?,
      originalPrice: (m['original_price'] as num?)?.toInt() ?? 0,
      discountedPrice: (m['discounted_price'] as num?)?.toInt() ?? 0,
      discountPercent: (m['discount_percent'] as num?)?.toInt() ?? 0,
      firstVisitPrice: (m['first_visit_price'] as num?)?.toInt() ?? 0,
      maxPoints: (m['max_points'] as num?)?.toInt() ?? 0,
      sido: m['sido'] as String?,
      sigungu: m['sigungu'] as String?,
      eupmyeondong: m['eupmyeondong'] as String?,
      roadAddress: m['road_address'] as String?,
      jibunAddress: m['jibun_address'] as String?,
      postalCode: m['postal_code'] as String?,
      regionId: regionCode,
      subRegionIds: subRegionCodes,
      latitude: lat,
      longitude: lng,
      categoryIds: categoryIds,
      features: features,
      adIntentTierCode: adTierCode,
      profileImageUrl: profileImage,
      galleryImageUrls: gallery,
      operatingHours: operatingHoursList,
      rating: (m['rating_avg'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
      qnaCount: (m['qna_count'] as num?)?.toInt() ?? 0,
      callCount: (m['call_count'] as num?)?.toInt() ?? 0,
      reservationButtonCount: (m['reservation_button_count'] as num?)?.toInt() ?? 0,
      consultRequests: (m['consult_request_count'] as num?)?.toInt() ?? 0,
      isPublished: m['is_published'] as bool? ?? true,
      createdAt: _parseDate(m['created_at']),
      updatedAt: _parseDate(m['updated_at']),
      metadata: Map<String, dynamic>.from(m['metadata'] as Map? ?? const {}),
    );
  }

  /// bosals 테이블 본체 insert/update용 payload (자식 테이블은 별도 처리).
  Map<String, dynamic> toBosalsRow() => {
        'id': id,
        if (slug != null) 'slug': slug,
        'name': name,
        'one_liner': oneLiner,
        'description': description,
        'experience_years': experienceYears,
        'phone_e164': phoneE164,
        'phone_display': phoneNumber,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'first_visit_price': firstVisitPrice,
        'max_points': maxPoints,
        'sido': sido,
        'sigungu': sigungu,
        'eupmyeondong': eupmyeondong,
        'road_address': roadAddress,
        'jibun_address': jibunAddress,
        'postal_code': postalCode,
        'is_published': isPublished,
        'metadata': metadata,
      };

  Bosal copyWith({
    String? profileImageUrl,
    int? callCount,
    int? reservationButtonCount,
    int? consultRequests,
    double? rating,
    int? reviewCount,
  }) =>
      Bosal(
        id: id,
        slug: slug,
        name: name,
        oneLiner: oneLiner,
        description: description,
        experienceYears: experienceYears,
        consultStyle: consultStyle,
        consultStyleCode: consultStyleCode,
        phoneNumber: phoneNumber,
        phoneE164: phoneE164,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        discountPercent: discountPercent,
        firstVisitPrice: firstVisitPrice,
        maxPoints: maxPoints,
        sido: sido,
        sigungu: sigungu,
        eupmyeondong: eupmyeondong,
        roadAddress: roadAddress,
        jibunAddress: jibunAddress,
        postalCode: postalCode,
        regionId: regionId,
        subRegionIds: subRegionIds,
        latitude: latitude,
        longitude: longitude,
        categoryIds: categoryIds,
        features: features,
        adIntentTierCode: adIntentTierCode,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        galleryImageUrls: galleryImageUrls,
        operatingHours: operatingHours,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        qnaCount: qnaCount,
        callCount: callCount ?? this.callCount,
        reservationButtonCount: reservationButtonCount ?? this.reservationButtonCount,
        consultRequests: consultRequests ?? this.consultRequests,
        isPublished: isPublished,
        createdAt: createdAt,
        updatedAt: updatedAt,
        metadata: metadata,
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
