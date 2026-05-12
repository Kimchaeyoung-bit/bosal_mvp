import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';

/// 비밀번호 재설정 — 이메일 입력 → Supabase Auth `resetPasswordForEmail`.
///
/// 메일 링크의 redirect URL은 Supabase Project Settings → Auth → URL
/// Configuration 에서 관리. MVP에서는 Supabase 기본 호스팅 페이지에서 비번을
/// 변경하고 사용자는 다시 앱에서 새 비번으로 로그인. 앱 deep link 기반
/// in-app 변경 흐름은 시나리오 C(푸시 알림과 함께) 에서 추가.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '이메일을 입력해주세요');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _submitting = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanize(e.message);
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '메일 발송에 실패했습니다.';
        _submitting = false;
      });
    }
  }

  String _humanize(String msg) {
    if (msg.contains('rate limit') || msg.contains('Too Many')) {
      return '요청이 너무 잦습니다. 잠시 후 다시 시도해주세요.';
    }
    return '메일 발송에 실패했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => dismissAuthScreen(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('비밀번호 찾기'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSent() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('가입 시 사용한 이메일을 입력해주세요',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          '재설정 링크가 포함된 메일을 보내드립니다. 메일이 오지 않으면 스팸함도 확인해주세요.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSub, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            hintText: 'name@example.com',
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
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.danger, fontSize: 13)),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('재설정 메일 보내기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('메일을 보냈습니다',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          '${_emailCtrl.text.trim()} 으로 비밀번호 재설정 링크를 보냈습니다.\n'
          '메일이 오지 않으면 스팸함을 확인하거나 잠시 후 다시 시도해주세요.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSub, fontSize: 14),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('로그인으로 돌아가기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
