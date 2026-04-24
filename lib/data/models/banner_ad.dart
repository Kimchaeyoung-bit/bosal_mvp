enum AdPlacement { homeTop, homeMid, detailBottom }

extension AdPlacementX on AdPlacement {
  String get dbValue {
    switch (this) {
      case AdPlacement.homeTop:
        return 'home_top';
      case AdPlacement.homeMid:
        return 'home_mid';
      case AdPlacement.detailBottom:
        return 'detail_bottom';
    }
  }

  static AdPlacement fromDb(String s) {
    switch (s) {
      case 'home_mid':
        return AdPlacement.homeMid;
      case 'detail_bottom':
        return AdPlacement.detailBottom;
      case 'home_top':
      default:
        return AdPlacement.homeTop;
    }
  }
}

class BannerAd {
  final String id;
  final String? bosalId;
  final String title;
  final String imageUrl;
  final String? targetUrl;
  final AdPlacement placement;
  final int weight;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;

  const BannerAd({
    required this.id,
    this.bosalId,
    required this.title,
    required this.imageUrl,
    this.targetUrl,
    this.placement = AdPlacement.homeTop,
    this.weight = 100,
    required this.startAt,
    required this.endAt,
    this.isActive = true,
  });

  factory BannerAd.fromMap(Map<String, dynamic> m) => BannerAd(
        id: m['id'] as String,
        bosalId: m['bosal_id'] as String?,
        title: m['title'] as String,
        imageUrl: m['image_url'] as String,
        targetUrl: m['target_url'] as String?,
        placement: AdPlacementX.fromDb(m['placement'] as String? ?? 'home_top'),
        weight: (m['weight'] as num?)?.toInt() ?? 100,
        startAt: DateTime.parse(m['start_at'] as String),
        endAt: DateTime.parse(m['end_at'] as String),
        isActive: m['is_active'] as bool? ?? true,
      );
}
