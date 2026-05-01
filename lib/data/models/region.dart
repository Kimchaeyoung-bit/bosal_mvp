class Region {
  final String id;            // DB regions.code
  final String name;
  final int sortOrder;
  final List<SubRegion> subRegions;

  const Region({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.subRegions = const [],
  });

  /// Supabase nested select: `select=*,sub_regions(code,name,sort_order,latitude,longitude)`
  factory Region.fromMap(Map<String, dynamic> m) {
    final subsRaw = (m['sub_regions'] as List?) ?? const [];
    final subs = subsRaw
        .cast<Map<String, dynamic>>()
        .map((s) => SubRegion(
              id: s['code'] as String,
              name: s['name'] as String,
              parentRegionId: m['code'] as String,
              sortOrder: (s['sort_order'] as num?)?.toInt() ?? 0,
              latitude: (s['latitude'] as num?)?.toDouble(),
              longitude: (s['longitude'] as num?)?.toDouble(),
            ))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Region(
      id: m['code'] as String,
      name: m['name'] as String,
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      subRegions: subs,
    );
  }
}

class SubRegion {
  final String id;
  final String name;
  final String parentRegionId;
  final int sortOrder;
  final double? latitude;
  final double? longitude;

  const SubRegion({
    required this.id,
    required this.name,
    required this.parentRegionId,
    this.sortOrder = 0,
    this.latitude,
    this.longitude,
  });
}
