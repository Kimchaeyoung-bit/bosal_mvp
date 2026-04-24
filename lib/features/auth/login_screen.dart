import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '아이디와 비밀번호를 입력해주세요');
      return;
    }

    final error = ref.read(authProvider.notifier).login(username, password);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    if (user.role == UserRole.bosal) {
      context.go('/bosal-home');
    } else {
      context.pop(true);
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
              // Back button
              GestureDetector(
                onTap: () => context.pop(false),
                child: const Icon(Icons.close_rounded, size: 28),
              ),

              const SizedBox(height: 40),

              // Logo area
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '강남보살',
                      style: AppTextStyles.largeName.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '로그인하고 나에게 맞는 보살을 찾아보세요',
                      style: AppTextStyles.small.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Username field
              Text('아이디', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: '아이디를 입력하세요',
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
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              const SizedBox(height: 16),

              // Password field
              Text('비밀번호', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
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
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSub,
                      size: 20,
                    ),
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handleLogin,
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
                  child: const Text('로그인'),
                ),
              ),

              const SizedBox(height: 16),

              // Sign up hint
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('계정이 없으신가요? ',
                        style: AppTextStyles.small.copyWith(fontSize: 13)),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '회원가입',
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
}
