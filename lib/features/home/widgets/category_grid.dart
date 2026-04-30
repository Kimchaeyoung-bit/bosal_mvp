import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category.dart';
import '../../../providers/category_provider.dart';
import '../../../shared/widgets/app_shadow.dart';

const _kMainCount = 7;

class CategoryGrid extends ConsumerWidget {
  final void Function(Category category) onCategoryTap;

  const CategoryGrid({super.key, required this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final mainCats = categories.take(_kMainCount).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: _kMainCount + 1,
      itemBuilder: (context, index) {
        if (index < _kMainCount) {
          final category = mainCats[index];
          return GestureDetector(
            onTap: () => onCategoryTap(category),
            behavior: HitTestBehavior.opaque,
            child: _CategoryCard(name: category.name, icon: category.icon),
          );
        }
        // 기타 카드
        return GestureDetector(
          onTap: () => context.push('/other-categories'),
          behavior: HitTestBehavior.opaque,
          child: const _CategoryCard(
            name: '기타',
            icon: Icons.more_horiz_rounded,
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;

  const _CategoryCard({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        boxShadow: appShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.text),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTextStyles.category.copyWith(
              fontSize: 11,
              color: AppColors.text,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
