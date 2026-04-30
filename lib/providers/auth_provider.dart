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

  static final _accounts = <String, AppUser>{
    // 일반 사용자 10명
    'a':   const AppUser(id: 'user_1',  username: 'a',   role: UserRole.user, displayName: '사용자1'),
    'a2':  const AppUser(id: 'user_2',  username: 'a2',  role: UserRole.user, displayName: '사용자2'),
    'a3':  const AppUser(id: 'user_3',  username: 'a3',  role: UserRole.user, displayName: '사용자3'),
    'a4':  const AppUser(id: 'user_4',  username: 'a4',  role: UserRole.user, displayName: '사용자4'),
    'a5':  const AppUser(id: 'user_5',  username: 'a5',  role: UserRole.user, displayName: '사용자5'),
    'a6':  const AppUser(id: 'user_6',  username: 'a6',  role: UserRole.user, displayName: '사용자6'),
    'a7':  const AppUser(id: 'user_7',  username: 'a7',  role: UserRole.user, displayName: '사용자7'),
    'a8':  const AppUser(id: 'user_8',  username: 'a8',  role: UserRole.user, displayName: '사용자8'),
    'a9':  const AppUser(id: 'user_9',  username: 'a9',  role: UserRole.user, displayName: '사용자9'),
    'a10': const AppUser(id: 'user_10', username: 'a10', role: UserRole.user, displayName: '사용자10'),
    // 보살 10명
    'b':   const AppUser(id: 'bosal_1',  username: 'b',   role: UserRole.bosal, displayName: '가가 보살', bosalId: '1'),
    'b2':  const AppUser(id: 'bosal_2',  username: 'b2',  role: UserRole.bosal, displayName: '나나 보살', bosalId: '2'),
    'b3':  const AppUser(id: 'bosal_3',  username: 'b3',  role: UserRole.bosal, displayName: '다다 보살', bosalId: '3'),
    'b4':  const AppUser(id: 'bosal_4',  username: 'b4',  role: UserRole.bosal, displayName: '라라 보살', bosalId: '4'),
    'b5':  const AppUser(id: 'bosal_5',  username: 'b5',  role: UserRole.bosal, displayName: '마마 보살', bosalId: '5'),
    'b6':  const AppUser(id: 'bosal_6',  username: 'b6',  role: UserRole.bosal, displayName: '달빛 보살', bosalId: '6'),
    'b7':  const AppUser(id: 'bosal_7',  username: 'b7',  role: UserRole.bosal, displayName: '청산 도령', bosalId: '7'),
    'b8':  const AppUser(id: 'bosal_8',  username: 'b8',  role: UserRole.bosal, displayName: '바바 보살', bosalId: '8'),
    'b9':  const AppUser(id: 'bosal_9',  username: 'b9',  role: UserRole.bosal, displayName: '사사 보살', bosalId: '9'),
    'b10': const AppUser(id: 'bosal_10', username: 'b10', role: UserRole.bosal, displayName: '아아 보살', bosalId: '10'),
  };

  String? login(String username, String password) {
    if (password != '1234') return '아이디 또는 비밀번호가 올바르지 않습니다';
    final user = _accounts[username];
    if (user == null) return '아이디 또는 비밀번호가 올바르지 않습니다';
    state = user;
    return null;
  }

  void logout() {
    state = null;
  }
}
