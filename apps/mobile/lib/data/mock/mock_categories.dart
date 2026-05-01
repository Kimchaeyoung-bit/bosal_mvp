import 'package:flutter/material.dart';
import '../models/category.dart';

final mockCategories = [
  // 메인 그리드 7개 (index 0~6)
  const Category(id: 'love',          name: '연애',    icon: Icons.favorite_border_rounded),
  const Category(id: 'career',        name: '취업',    icon: Icons.work_outline_rounded),
  const Category(id: 'wealth',        name: '재물',    icon: Icons.paid_outlined),
  const Category(id: 'health',        name: '건강',    icon: Icons.spa_outlined),
  const Category(id: 'relationship',  name: '인간관계', icon: Icons.people_outline_rounded),
  const Category(id: 'tarot',         name: '타로',    icon: Icons.auto_awesome_outlined),
  const Category(id: 'business',      name: '사업',    icon: Icons.business_center_outlined),
  // 기타 4개 (index 7~10)
  const Category(id: 'newyear',       name: '신년운세', icon: Icons.celebration_outlined),
  const Category(id: 'compatibility', name: '궁합',    icon: Icons.volunteer_activism_outlined),
  const Category(id: 'dream',         name: '꿈해몽',   icon: Icons.bedtime_outlined),
  const Category(id: 'naming',        name: '작명',    icon: Icons.edit_outlined),
];
