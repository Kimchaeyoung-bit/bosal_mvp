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
