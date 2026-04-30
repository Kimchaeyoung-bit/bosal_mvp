import 'package:flutter/material.dart';
import '../models/category.dart';

final mockCategories = [
  const Category(id: 'all', name: '전체', icon: Icons.grid_view_outlined),
  const Category(id: 'love', name: '연애', icon: Icons.favorite_border_rounded),
  const Category(id: 'career', name: '취업', icon: Icons.work_outline_rounded),
  const Category(id: 'wealth', name: '재물', icon: Icons.paid_outlined),
  const Category(id: 'health', name: '건강', icon: Icons.spa_outlined),
  const Category(id: 'relationship', name: '인간관계', icon: Icons.people_outline_rounded),
  const Category(id: 'tarot', name: '타로', icon: Icons.auto_awesome_outlined),
  const Category(id: 'business', name: '사업', icon: Icons.business_center_outlined),
];
