/// The values the server accepts for a user's sex.
enum Sex {
  male,
  female,
  other;

  static Sex? fromApi(String? value) =>
      values.where((sex) => sex.name == value).firstOrNull;
}

/// The signed-in user's own account, as `GET /users/me` returns it.
class UserProfile {
  final String id;
  final String? email;
  final String? phone;

  /// The unique handle. Null only for an account the server has not given
  /// one yet.
  final String? username;

  /// The name other people see. Several users may share one.
  final String? name;
  final String? firstName;
  final String? lastName;
  final Sex? sex;
  final String role;
  final DateTime createdAt;
  final String? firebaseUid;
  final String? avatarUrl;

  /// True while the picture is the Google account's photo and follows it
  /// ("Sync from Google account").
  final bool avatarFromGoogle;

  /// False for an account made by Google sign-in whose owner has not chosen
  /// a password yet: it has nothing to type where a password is asked for.
  final bool hasPassword;

  const UserProfile({
    required this.id,
    this.email,
    this.phone,
    this.username,
    this.name,
    this.firstName,
    this.lastName,
    this.sex,
    required this.role,
    required this.createdAt,
    this.firebaseUid,
    this.avatarUrl,
    this.avatarFromGoogle = false,
    this.hasPassword = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
      name: json['name'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      sex: Sex.fromApi(json['sex'] as String?),
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] as String),
      firebaseUid: json['firebaseUid'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarFromGoogle: json['avatarFromGoogle'] == true,
      // A server that does not say (an older one) is taken at its word
      // that a password exists, as before.
      hasPassword: json['hasPassword'] != false,
    );
  }

  /// The best thing to call this user: their name, else their handle, phone
  /// or the part of their email before the "@". Null when none is known.
  String? get displayName {
    for (final candidate in [name, username, phone, email?.split('@').first]) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// True when the account is linked to Google sign-in, so the owner can
  /// confirm who they are with Google instead of a password.
  bool get signsInWithGoogle => firebaseUid != null;
}
