import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/auth_data_source.dart';
import '../data/models/app_user.dart';
import 'data_source_providers.dart';

/// 현재 로그인한 사용자. null 이면 로그아웃 상태.
final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  final notifier = AuthNotifier(ref.watch(authDataSourceProvider));
  // Supabase 세션 복원/외부 로그아웃 반영
  final sub = ref
      .watch(authDataSourceProvider)
      .authStateChanges()
      .listen(notifier._setFromStream);
  ref.onDispose(sub.cancel);
  return notifier;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider)?.role;
});

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier(this._dataSource) : super(_dataSource.currentUser);

  final AuthDataSource _dataSource;

  /// 로그인. 성공 시 (null, user) / 실패 시 (errorMsg, null).
  /// 호출자는 user 결과로 분기 (state race 회피).
  Future<({String? error, AppUser? user})> login(
    String emailOrUsername,
    String password,
  ) async {
    try {
      final user = await _dataSource.signInWithPassword(
        emailOrUsername: emailOrUsername,
        password: password,
      );
      state = user;
      return (error: null, user: user);
    } on AuthFailure catch (e) {
      return (error: e.message, user: null);
    } catch (e) {
      return (error: '로그인에 실패했습니다', user: null);
    }
  }

  /// 회원가입 (이메일/비밀번호).
  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _dataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = user;
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    } catch (e) {
      return '회원가입에 실패했습니다';
    }
  }

  Future<String?> claimBosalInvite(String code) async {
    try {
      await _dataSource.claimBosalInvite(code);
      // refresh current user (role/bosal_id bumped)
      state = _dataSource.currentUser;
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    } catch (e) {
      return '초대 코드 적용 실패';
    }
  }

  Future<void> logout() async {
    await _dataSource.signOut();
    state = null;
  }

  void _setFromStream(AppUser? u) {
    state = u;
  }
}
