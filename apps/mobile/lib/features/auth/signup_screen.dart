import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;
  String? _info;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;
    final name = _displayNameCtrl.text.trim();
    final inviteCode = _inviteCodeCtrl.text.trim();

    if (email.isEmpty || pw.isEmpty || name.isEmpty) {
      setState(() => _error = '이메일·비밀번호·이름을 입력해주세요');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = '비밀번호는 6자 이상이어야 합니다');
      return;
    }
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() => _error = '이용약관과 개인정보처리방침에 모두 동의해주세요');
      return;
    }

    setState(() => _submitting = true);
    try {
      final signupError = await ref.read(authProvider.notifier).signUp(
            email: email,
            password: pw,
            displayName: name,
          );
      if (signupError != null) {
        setState(() {
          _error = signupError;
          _submitting = false;
        });
        return;
      }

      // 초대 코드가 있으면 claim
      if (inviteCode.isNotEmpty) {
        final claimError =
            await ref.read(authProvider.notifier).claimBosalInvite(inviteCode);
        if (claimError != null) {
          setState(() {
            _info = '계정은 생성됐지만 초대 코드 적용 실패: $claimError';
            _submitting = false;
          });
          return;
        }
      }

      if (!mounted) return;
      final user = ref.read(authProvider);
      if (user?.role == UserRole.bosal) {
        context.go('/bosal-onboarding');
      } else {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => dismissAuthScreen(context),
                child: const Icon(Icons.close_rounded, size: 28),
              ),
              const SizedBox(height: 32),
              Text('회원가입', style: AppTextStyles.largeName.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                '이메일로 가입하고 시작해보세요. 보살로 가입하려면 관리자에게 받은 초대 코드를 입력하세요.',
                style: AppTextStyles.small.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 32),

              _fieldLabel('이메일'),
              _textField(
                controller: _emailCtrl,
                hint: 'example@email.com',
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),
              _fieldLabel('비밀번호 (6자 이상)'),
              _textField(
                controller: _passwordCtrl,
                hint: '비밀번호',
                obscure: _obscure,
                trailing: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSub,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              const SizedBox(height: 16),
              _fieldLabel('이름'),
              _textField(controller: _displayNameCtrl, hint: '예: 김보살'),

              const SizedBox(height: 24),

              // Optional invite code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Text('보살 초대 코드 (선택)', style: AppTextStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '관리자가 발급한 코드를 입력하면 보살로 가입됩니다.',
                      style: AppTextStyles.small.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _inviteCodeCtrl,
                      hint: '예: BOSAL-A3F8-2B91',
                      autoUppercase: true,
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.small
                            .copyWith(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(
                  _info!,
                  style: AppTextStyles.small.copyWith(fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // 약관·개인정보 동의 (가입 필수)
              _ConsentRow(
                checked: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                label: '이용약관에 동의합니다',
                onLinkTap: () => context.push('/legal/terms'),
              ),
              const SizedBox(height: 6),
              _ConsentRow(
                checked: _agreePrivacy,
                onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                label: '개인정보처리방침에 동의합니다',
                onLinkTap: () => context.push('/legal/privacy'),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('가입하기'),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('이미 계정이 있으신가요? ',
                        style: AppTextStyles.small.copyWith(fontSize: 13)),
                    GestureDetector(
                      onTap: () => dismissAuthScreen(context),
                      child: Text(
                        '로그인',
                        style: AppTextStyles.small.copyWith(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.bodyBold),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool autoUppercase = false,
    TextInputType? keyboard,
    Widget? trailing,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        textCapitalization:
            autoUppercase ? TextCapitalization.characters : TextCapitalization.none,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSub),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: trailing,
        ),
        onChanged: (_) => setState(() => _error = null),
      );
}

class _ConsentRow extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onLinkTap;

  const _ConsentRow({
    required this.checked,
    required this.onChanged,
    required this.label,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: checked,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!checked),
            behavior: HitTestBehavior.opaque,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
          ),
        ),
        TextButton(
          onPressed: onLinkTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '보기',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
