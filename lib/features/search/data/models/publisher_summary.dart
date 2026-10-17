/// Someone who posts listings (a person or an agency), as search shows them.
class PublisherSummary {
  final String id;
  final String? name;
  final String? username;
  final String? avatarUrl;

  /// Published listings only.
  final int listingCount;

  /// When the account was created.
  final DateTime? memberSince;

  /// How to reach them. Only their profile page receives these; search
  /// result lists never do.
  final String? email;
  final String? phone;

  const PublisherSummary({
    required this.id,
    this.name,
    this.username,
    this.avatarUrl,
    this.listingCount = 0,
    this.memberSince,
    this.email,
    this.phone,
  });

  /// The name people chose, else their handle.
  String get displayName {
    final chosen = name?.trim();
    if (chosen != null && chosen.isNotEmpty) return chosen;
    return username ?? '';
  }

  factory PublisherSummary.fromJson(Map<String, dynamic> json) {
    return PublisherSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
      memberSince: DateTime.tryParse(json['memberSince'] as String? ?? ''),
      email: _present(json['email']),
      phone: _present(json['phone']),
    );
  }

  static String? _present(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
