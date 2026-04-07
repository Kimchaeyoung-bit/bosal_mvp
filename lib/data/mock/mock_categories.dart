import 'package:flutter/material.dart';
import '../models/category.dart';

final mockCategories = [
  const Category(id: 'all', name: '전체', icon: Icons.grid_view_rounded),
  const Category(id: 'love', name: '연애', icon: Icons.favorite_rounded),
  const Category(id: 'career', name: '취업', icon: Icons.work_rounded),
  const Category(id: 'wealth', name: '재물', icon: Icons.monetization_on_rounded),
  const Category(id: 'health', name: '건강', icon: Icons.spa_rounded),
  const Category(id: 'relationship', name: '인간관계', icon: Icons.people_rounded),
  const Category(id: 'tarot', name: '타로', icon: Icons.auto_awesome_rounded),
];
