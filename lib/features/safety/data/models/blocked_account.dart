/// Someone the signed-in user blocked, as the list to unblock from shows them.
class BlockedAccount {
  final String id;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final DateTime? blockedAt;

  const BlockedAccount({
    required this.id,
    this.name,
    this.username,
    this.avatarUrl,
    this.blockedAt,
  });

  /// Their name, else their username.
  String get displayName {
    final chosen = name?.trim();
    if (chosen != null && chosen.isNotEmpty) return chosen;
    return username ?? '';
  }

  factory BlockedAccount.fromJson(Map<String, dynamic> json) {
    return BlockedAccount(
      id: json['id'] as String,
      name: json['name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
    );
  }
}
