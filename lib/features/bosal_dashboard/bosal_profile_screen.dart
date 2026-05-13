import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_shadow.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bosal_provider.dart';

class BosalProfileScreen extends ConsumerStatefulWidget {
  const BosalProfileScreen({super.key});

  @override
  ConsumerState<BosalProfileScreen> createState() => _BosalProfileScreenState();
}

class _BosalProfileScreenState extends ConsumerState<BosalProfileScreen> {
  bool _isPublic = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final bosals = ref.watch(allBosalsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final myBosal = user?.bosalId != null
        ? bosals.where((b) => b.id == user!.bosalId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 16),
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
                  color: AppColors.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: appShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo_real.png',
                        fit: BoxFit.contain,
                      ),
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

            const SizedBox(height: 12),

            // 공개/비공개 토글
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: appShadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPublic ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                      color: _isPublic ? const Color(0xFF2ECC71) : AppColors.textSub,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('프로필 공개 상태', style: AppTextStyles.bodyBold),
                          Text(
                            _isPublic ? '고객에게 노출 중' : '비공개 상태입니다',
                            style: AppTextStyles.small.copyWith(
                              color: _isPublic ? const Color(0xFF2ECC71) : AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primarySoft,
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
                value: myBosal.description ?? '소개를 입력해주세요',
                onEdit: () => _showEditSnack(context),
              ),
              _ProfileSection(
                title: '전문 분야',
                value: myBosal.features.join(', '),
                onEdit: () => _showEditSnack(context),
              ),
              _ProfileSection(
                title: '상담 스타일',
                value: myBosal.consultStyle,
                onEdit: () => _showEditSnack(context),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
        ),
      ),
    );
  }

  void _showEditSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('편집 기능은 준비 중입니다'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: AppColors.surface.withValues(alpha: 0.75),
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
