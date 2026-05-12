import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

Future<void> requireAuth(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onAuthenticated,
}) async {
  final isLoggedIn = ref.read(isLoggedInProvider);

  if (isLoggedIn) {
    onAuthenticated();
    return;
  }

  final result = await context.push<bool>('/login');
  if (result == true && context.mounted) {
    onAuthenticated();
  }
}

/// 인증 화면(login/signup/password-reset)의 X·뒤로가기 처리.
///
/// 라우터 redirect(P1-2)로 진입한 경우 navigation stack이 비어 있어
/// `context.pop()`이 무동작이라 사용자가 화면에 갇힌다. 그 경우 `/home`으로
/// fallback. pop이 가능하면 정상 pop (상위 화면이 결과 받기 위함).
void dismissAuthScreen(BuildContext context, {Object? popResult}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop(popResult);
  } else {
    router.go('/home');
  }
}

void showLoginRequiredSnack(BuildContext context, {String? message}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message ?? '로그인이 필요합니다'),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: '로그인',
        onPressed: () => context.push('/login'),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
