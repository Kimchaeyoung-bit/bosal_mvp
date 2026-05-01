class Region {
  final String id;
  final String name;
  final List<SubRegion> subRegions;

  const Region({
    required this.id,
    required this.name,
    required this.subRegions,
  });
}

class SubRegion {
  final String id;
  final String name;
  final String parentRegionId;
  final double? latitude;
  final double? longitude;

  const SubRegion({
    required this.id,
    required this.name,
    required this.parentRegionId,
    this.latitude,
    this.longitude,
  });
}
