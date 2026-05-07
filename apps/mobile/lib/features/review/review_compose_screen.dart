import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/review_provider.dart';

/// 리뷰 작성 화면.
///
/// 진입: `/review/compose?bosalId=...&reservationId=...&bosalName=...`
/// - completed 예약 보유자만 등록 가능 (DB 트리거가 강제)
/// - reservationId 미지정 시 해당 보살에 대한 단일 리뷰만 가능 (트리거)
class ReviewComposeScreen extends ConsumerStatefulWidget {
  final String bosalId;
  final String? reservationId;
  final String? bosalName;

  const ReviewComposeScreen({
    super.key,
    required this.bosalId,
    this.reservationId,
    this.bosalName,
  });

  @override
  ConsumerState<ReviewComposeScreen> createState() =>
      _ReviewComposeScreenState();
}

class _ReviewComposeScreenState extends ConsumerState<ReviewComposeScreen> {
  int _rating = 10; // DB 1..10
  bool _isPublic = true;
  bool _submitting = false;
  String? _error;
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await ref.read(reviewActionsProvider).create(
            bosalId: widget.bosalId,
            reservationId: widget.reservationId,
            rating: _rating,
            body: _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
            isPublic: _isPublic,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('후기가 등록되었습니다')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanize(e);
        _submitting = false;
      });
    }
  }

  String _humanize(Object e) {
    final s = e.toString();
    if (s.contains('only users with a completed reservation')) {
      return '상담 완료 후에만 후기를 작성할 수 있습니다.';
    }
    if (s.contains('duplicate key') ||
        s.contains('unique') ||
        s.contains('reviews_reservation_id_key')) {
      return '이미 후기를 작성하셨습니다.';
    }
    if (s.contains('not authenticated') || s.contains('JWT')) {
      return '로그인이 만료되었습니다. 다시 로그인해주세요.';
    }
    if (s.contains('rating') && s.contains('check')) {
      return '평점은 1점에서 10점 사이여야 합니다.';
    }
    if (s.contains('SocketException') || s.contains('Network')) {
      return '네트워크 연결을 확인해주세요.';
    }
    // raw exception 노출 차단
    return '후기 등록에 실패했습니다. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final stars = (_rating / 2).round();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('후기 작성'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.bosalName != null) ...[
                Text(widget.bosalName!,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
              ],
              Text('상담은 어떠셨나요?',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSub)),
              const SizedBox(height: 20),
              // 별점
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < stars;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = (i + 1) * 2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 36,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$_rating / 10',
                  style: AppTextStyles.small,
                ),
              ),
              const SizedBox(height: 24),
              // 본문
              TextField(
                controller: _bodyCtrl,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: '상담 경험을 자세히 들려주세요 (선택)',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('다른 회원에게 공개', style: AppTextStyles.body),
                subtitle: Text(
                  _isPublic
                      ? '보살 상세 페이지에 노출됩니다'
                      : '보살에게만 보이는 비공개 후기입니다',
                  style: AppTextStyles.small,
                ),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.small.copyWith(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('후기 등록',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
