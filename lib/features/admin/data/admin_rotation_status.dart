class AdminRotationStatus {
  final String status;
  final String? environment;
  final DateTime checkedAt;
  final List<AdminCredentialRotation> credentials;

  AdminRotationStatus.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String,
      environment = json['environment'] as String?,
      checkedAt = DateTime.parse(json['checkedAt'] as String),
      credentials = (json['credentials'] as List)
          .map(
            (item) =>
                AdminCredentialRotation.fromJson(item as Map<String, dynamic>),
          )
          .toList();
}

class AdminCredentialRotation {
  final String name;
  final String status;
  final DateTime? lastRotatedAt;

  AdminCredentialRotation.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      status = json['status'] as String,
      lastRotatedAt = DateTime.tryParse(json['lastRotatedAt'] as String? ?? '');
}
