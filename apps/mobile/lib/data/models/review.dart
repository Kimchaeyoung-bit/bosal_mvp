class Review {
  final String id;
  final String bosalId;
  final String? reservationId;
  final String userId;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final int rating;                 // 1..10
  final String? body;
  final bool isPublic;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.bosalId,
    this.reservationId,
    required this.userId,
    this.userDisplayName,
    this.userAvatarUrl,
    required this.rating,
    this.body,
    this.isPublic = true,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> m) {
    final author = m['author'] as Map<String, dynamic>?;
    return Review(
      id: m['id'] as String,
      bosalId: m['bosal_id'] as String,
      reservationId: m['reservation_id'] as String?,
      userId: m['user_id'] as String,
      userDisplayName: author?['display_name'] as String?,
      userAvatarUrl: author?['avatar_url'] as String?,
      rating: (m['rating'] as num).toInt(),
      body: m['body'] as String?,
      isPublic: m['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
