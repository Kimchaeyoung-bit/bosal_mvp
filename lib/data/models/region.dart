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

  const SubRegion({
    required this.id,
    required this.name,
    required this.parentRegionId,
  });
}
