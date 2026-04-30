enum UserRole { user, bosal }

class AppUser {
  final String id;
  final String username;
  final UserRole role;
  final String? bosalId;
  final String displayName;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.bosalId,
    required this.displayName,
  });
}
