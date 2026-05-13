class Bosal {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int reviewCount;
  final int qnaCount;
  final List<String> features;
  final int originalPrice;
  final int discountedPrice;
  final int discountPercent;
  final int firstVisitPrice;
  final int maxPoints;
  final int consultRequests;
  final String regionId;
  final List<String> subRegionIds;
  final List<String> categoryIds;
  final String? description;
  final int experienceYears;
  final String consultStyle;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? address;
  final List<String> operatingDays;
  final String? operatingHours;
  final bool isAdEnabled;

  const Bosal({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.rating,
    required this.reviewCount,
    required this.qnaCount,
    required this.features,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.firstVisitPrice,
    required this.maxPoints,
    required this.consultRequests,
    required this.regionId,
    required this.subRegionIds,
    required this.categoryIds,
    this.description,
    required this.experienceYears,
    required this.consultStyle,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.address,
    this.operatingDays = const [],
    this.operatingHours,
    this.isAdEnabled = false,
  });
}
