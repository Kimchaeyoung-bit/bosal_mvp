import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';

class BosalProfileScreen extends ConsumerWidget {
  const BosalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final bosals = ref.watch(allBosalsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final myBosal = user?.bosalId != null
        ? bosals.where((b) => b.id == user!.bosalId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 16),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('프로필 관리',
                      style:
                          AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
                  TextButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/home');
                    },
                    child: Text('로그아웃',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.danger)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: appShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 14),
                    Text(myBosal?.name ?? '', style: AppTextStyles.largeName),
                    const SizedBox(height: 4),
                    if (myBosal != null)
                      Text(
                        '경력 ${myBosal.experienceYears}년 · ${myBosal.consultStyle}',
                        style: AppTextStyles.small,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Editable sections
            if (myBosal != null) ...[
              _ProfileSection(
                title: '한 줄 소개',
                value: myBosal.description ?? '',
                onEdit: () {},
              ),
              _ProfileSection(
                title: '전문 분야',
                value: myBosal.features.join(', '),
                onEdit: () {},
              ),
              _ProfileSection(
                title: '상담 스타일',
                value: myBosal.consultStyle,
                onEdit: () {},
              ),
              _ProfileSection(
                title: '상담료',
                value: '${myBosal.discountedPrice}원 (원가 ${myBosal.originalPrice}원)',
                onEdit: () {},
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onEdit;

  const _ProfileSection({
    required this.title,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: appShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.small
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: AppTextStyles.body),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
