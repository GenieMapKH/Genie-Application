/// What a profile shows about following: counts only, never who.
class FollowSummary {
  final int followerCount;
  final int followingCount;

  /// Whether the signed-in user follows this person. False on their own
  /// profile.
  final bool isFollowing;

  const FollowSummary({
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory FollowSummary.fromJson(Map<String, dynamic> json) {
    return FollowSummary(
      followerCount: (json['followerCount'] as num).toInt(),
      followingCount: (json['followingCount'] as num).toInt(),
      isFollowing: json['isFollowing'] as bool,
    );
  }

  /// As it will be once the server has [following]: shown at once, before
  /// the server answers.
  FollowSummary expecting({required bool following}) {
    if (following == isFollowing) return this;
    return FollowSummary(
      followerCount: followerCount + (following ? 1 : -1),
      followingCount: followingCount,
      isFollowing: following,
    );
  }
}
