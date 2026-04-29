import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category.dart';
import '../../../providers/category_provider.dart';

class CategoryGrid extends ConsumerWidget {
  final void Function(Category category) onCategoryTap;
  const CategoryGrid({super.key, required this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => onCategoryTap(category),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  style: AppTextStyles.category.copyWith(
                    fontSize: 11,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
