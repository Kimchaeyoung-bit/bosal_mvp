/// 사용자 역할. DB enum `user_role`와 매칭.
enum UserRole { user, bosal, admin }

extension UserRoleX on UserRole {
  String get dbValue => toString().split('.').last;

  static UserRole fromDb(String s) {
    switch (s) {
      case 'admin':
        return UserRole.admin;
      case 'bosal':
        return UserRole.bosal;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

/// 앱 전역에서 사용하는 현재 사용자 표현.
///
/// - `id`는 Supabase `auth.users.id` == `profiles.id`.
/// - `username`은 현재 로그인 식별자 역할로만 사용 (추후 이메일로 이행 예정).
/// - `bosalId`는 role=bosal일 때 해당 보살 프로필 UUID.
class AppUser {
  final String id;
  final String username;
  final UserRole role;
  final String? bosalId;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.bosalId,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  /// profiles row → AppUser.
  factory AppUser.fromProfile(
    Map<String, dynamic> m, {
    String? email,
  }) =>
      AppUser(
        id: m['id'] as String,
        username: email ?? (m['display_name'] as String? ?? ''),
        role: UserRoleX.fromDb(m['role'] as String? ?? 'user'),
        bosalId: m['bosal_id'] as String?,
        displayName: m['display_name'] as String? ?? '',
        email: email,
        avatarUrl: m['avatar_url'] as String?,
      );
}
