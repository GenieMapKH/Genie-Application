class AdminServiceHealth {
  final String name;
  final String status;
  final int? latencyMs;
  final int? httpStatus;

  AdminServiceHealth.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      status = json['status'] as String,
      latencyMs = json['latencyMs'] as int?,
      httpStatus = json['httpStatus'] as int?;
}

class AdminSystemHealth {
  final DateTime checkedAt;
  final List<AdminServiceHealth> services;

  AdminSystemHealth.fromJson(Map<String, dynamic> json)
    : checkedAt = DateTime.parse(json['checkedAt'] as String),
      services = (json['services'] as List)
          .map(
            (item) => AdminServiceHealth.fromJson(item as Map<String, dynamic>),
          )
          .toList();
}
