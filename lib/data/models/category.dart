import 'package:flutter/material.dart';

class Category {
  /// DB에서는 categories.code를 id로 매핑.
  final String id;
  final String name;
  final IconData icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  /// Supabase row → Category. `icon_key`(text)를 Flutter IconData로 변환한다.
  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['code'] as String,
        name: m['name'] as String,
        icon: iconFromKey(m['icon_key'] as String?),
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );
}

/// icon_key 문자열 → Flutter Icons 매핑.
///
/// DB에서는 문자열로만 저장하고 클라이언트에서 아이콘을 결정한다. 이렇게 해야
/// 관리자 UI에서 카테고리를 추가해도 앱을 배포하지 않고 사용할 수 있다.
IconData iconFromKey(String? key) {
  switch (key) {
    case 'grid_view_rounded':
      return Icons.grid_view_rounded;
    case 'favorite_rounded':
      return Icons.favorite_rounded;
    case 'work_rounded':
      return Icons.work_rounded;
    case 'monetization_on_rounded':
      return Icons.monetization_on_rounded;
    case 'spa_rounded':
      return Icons.spa_rounded;
    case 'people_rounded':
      return Icons.people_rounded;
    case 'auto_awesome_rounded':
      return Icons.auto_awesome_rounded;
    case 'business_center_rounded':
      return Icons.business_center_rounded;
    default:
      return Icons.label_rounded;
  }
}
