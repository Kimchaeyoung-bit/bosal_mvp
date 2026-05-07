import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// 회원 탈퇴 화면.
///
/// `delete_my_account('탈퇴합니다')` RPC 호출 → 프로필 anonymize + auth 정지.
/// 정확한 확인 문구를 입력해야 활성화 (실수 방지).
class AccountDeleteScreen extends ConsumerStatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  ConsumerState<AccountDeleteScreen> createState() =>
      _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends ConsumerState<AccountDeleteScreen> {
  static const _confirmPhrase = '탈퇴합니다';
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await supabase.rpc('delete_my_account', params: {
        'p_confirm': _confirmCtrl.text.trim(),
      });
      // 로그아웃 처리
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴가 완료되었습니다.')),
      );
      context.go('/home');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanize(e.message);
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '탈퇴 처리에 실패했습니다. 잠시 후 다시 시도해주세요.';
        _submitting = false;
      });
    }
  }

  String _humanize(String s) {
    if (s.contains('confirmation phrase mismatch')) {
      return '확인 문구가 일치하지 않습니다.';
    }
    if (s.contains('not authenticated') || s.contains('JWT')) {
      return '로그인이 만료되었습니다. 다시 로그인 후 시도해주세요.';
    }
    return '탈퇴 처리에 실패했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _confirmCtrl.text.trim() == _confirmPhrase && !_submitting;
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
        title: const Text('회원 탈퇴'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정말 탈퇴하시겠어요?',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 22)),
              const SizedBox(height: 12),
              Text(
                '탈퇴 시 다음과 같이 처리됩니다.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 12),
              const _NoticeItem(text: '회원 표시명·아바타는 즉시 익명 처리됩니다.'),
              const _NoticeItem(text: '찜·알림 데이터는 즉시 삭제됩니다.'),
              const _NoticeItem(text: '예약·후기 기록은 통계 무결성을 위해 익명 상태로 유지됩니다.'),
              const _NoticeItem(text: '동일 이메일로 즉시 재가입할 수 없습니다.'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '확인을 위해 아래 문구를 그대로 입력해주세요.',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _confirmPhrase,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: AppColors.danger,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: '확인 문구 입력',
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
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.small
                      .copyWith(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSubmit ? _delete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        AppColors.danger.withValues(alpha: 0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
                      : const Text('탈퇴 진행',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('취소'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  final String text;
  const _NoticeItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.textSub),
          ),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
