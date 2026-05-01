import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb
    show AuthException;

import '../models/app_user.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthDataSource {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signInWithPassword({
    required String emailOrUsername,
    required String password,
  });

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  /// 보살 초대 코드를 수락하여 현재 계정을 role=bosal 로 승격한다.
  /// 반환: 연결된 bosals.id
  Future<String> claimBosalInvite(String code);
}

// ================================================================
// Mock — preserves original hardcoded login semantics.
//   Reads TEST_USER_*/TEST_BOSAL_* from .env.
// ================================================================
class MockAuthDataSource implements AuthDataSource {
  AppUser? _current;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signInWithPassword({
    required String emailOrUsername,
    required String password,
  }) async {
    final testUser = dotenv.env['TEST_USER_USERNAME'];
    final testUserPw = dotenv.env['TEST_USER_PASSWORD'];
    final testBosal = dotenv.env['TEST_BOSAL_USERNAME'];
    final testBosalPw = dotenv.env['TEST_BOSAL_PASSWORD'];

    if (emailOrUsername == testUser && password == testUserPw) {
      _current = const AppUser(
        id: 'user_1',
        username: 'a',
        role: UserRole.user,
        displayName: '사용자',
      );
    } else if (emailOrUsername == testBosal && password == testBosalPw) {
      _current = const AppUser(
        id: 'bosal_1',
        username: 'b',
        role: UserRole.bosal,
        bosalId: '1',
        displayName: '가가 보살',
      );
    } else {
      throw AuthFailure('아이디 또는 비밀번호가 올바르지 않습니다');
    }
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    throw AuthFailure('mock 모드에서는 회원가입을 지원하지 않습니다');
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String> claimBosalInvite(String code) async {
    throw AuthFailure('mock 모드에서는 초대 코드를 처리할 수 없습니다');
  }
}

// ================================================================
// Supabase
// ================================================================
class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseAuthDataSource(this._client);
  final SupabaseClient _client;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    // currentUser는 cached profile 없이 반환; profile 로딩은 AuthRepository에서.
    return AppUser(
      id: user.id,
      username: user.email ?? user.id,
      role: UserRole.user,
      displayName: (user.userMetadata?['display_name'] as String?) ??
          (user.email?.split('@').first ?? '사용자'),
      email: user.email,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return AppUser(
        id: user.id,
        username: user.email ?? user.id,
        role: UserRole.user,
        displayName: (user.userMetadata?['display_name'] as String?) ??
            (user.email?.split('@').first ?? '사용자'),
        email: user.email,
      );
    });
  }

  @override
  Future<AppUser> signInWithPassword({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: emailOrUsername,
        password: password,
      );
      final user = res.user;
      if (user == null) throw AuthFailure('로그인 실패');
      return await _hydrateProfile(user.id, user.email);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      final user = res.user;
      if (user == null) throw AuthFailure('회원가입 실패');
      return await _hydrateProfile(user.id, user.email);
    } on sb.AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async => _client.auth.signOut();

  @override
  Future<String> claimBosalInvite(String code) async {
    final result = await _client.rpc('claim_bosal_invite', params: {
      'p_code': code,
    });
    return result as String;
  }

  Future<AppUser> _hydrateProfile(String userId, String? email) async {
    // profiles row는 auth.users insert 트리거로 자동 생성되지만,
    // signUp 직후 race condition을 피하기 위해 maybeSingle로 받는다.
    final row = await _client
        .from('profiles')
        .select('id,role,display_name,bosal_id,avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      // 아직 트리거가 실행되지 않은 경우: in-memory 기본값 반환
      return AppUser(
        id: userId,
        username: email ?? userId,
        role: UserRole.user,
        displayName: email?.split('@').first ?? '사용자',
        email: email,
      );
    }
    return AppUser.fromProfile(row, email: email);
  }
}

