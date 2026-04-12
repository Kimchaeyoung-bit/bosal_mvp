import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider)?.role;
});

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  String? login(String username, String password) {
    if (username == 'a' && password == '1234') {
      state = const AppUser(
        id: 'user_1',
        username: 'a',
        role: UserRole.user,
        displayName: '사용자',
      );
      return null;
    }

    if (username == 'b' && password == '1234') {
      state = const AppUser(
        id: 'bosal_1',
        username: 'b',
        role: UserRole.bosal,
        bosalId: '1',
        displayName: '가가 보살',
      );
      return null;
    }

    return '아이디 또는 비밀번호가 올바르지 않습니다';
  }

  void logout() {
    state = null;
  }
}
