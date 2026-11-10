class AdminWorkflowStatus {
  final String status;
  final bool busy;
  final List<AdminWorkflowRun> runs;
  AdminWorkflowStatus.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String,
      busy = json['busy'] as bool,
      runs = (json['runs'] as List)
          .map((r) => AdminWorkflowRun.fromJson(r as Map<String, dynamic>))
          .toList();
}

class AdminWorkflowRun {
  final String status;
  final String? conclusion;
  final DateTime createdAt;
  AdminWorkflowRun.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String,
      conclusion = json['conclusion'] as String?,
      createdAt = DateTime.parse(json['createdAt'] as String);
}

class AdminLogEntry {
  final String id;
  final DateTime timestamp;
  final String project;
  final String level;
  final String message;
  AdminLogEntry.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      timestamp = DateTime.parse(json['timestamp'] as String),
      project = json['project'] as String,
      level = json['level'] as String,
      message = json['message'] as String;
}

class AdminLogPage {
  final String status;
  final DateTime checkedAt;
  final String? environment;
  final String? nextCursor;
  final List<AdminLogEntry> entries;
  final bool busy;
  final bool refreshFailed;
  const AdminLogPage({
    required this.status,
    required this.checkedAt,
    this.environment,
    this.nextCursor,
    required this.entries,
    this.busy = false,
    this.refreshFailed = false,
  });
  factory AdminLogPage.fromJson(Map<String, dynamic> json) => AdminLogPage(
    status: json['status'] as String,
    checkedAt: DateTime.parse(json['checkedAt'] as String),
    environment: json['environment'] as String?,
    nextCursor: json['nextCursor'] as String?,
    entries: (json['entries'] as List)
        .map((r) => AdminLogEntry.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
  AdminLogPage copyWith({bool? busy, bool? refreshFailed}) => AdminLogPage(
    status: status,
    checkedAt: checkedAt,
    environment: environment,
    nextCursor: nextCursor,
    entries: entries,
    busy: busy ?? this.busy,
    refreshFailed: refreshFailed ?? this.refreshFailed,
  );
}

class AdminDeployment {
  final String id;
  final String status;
  final String? commit;
  final DateTime createdAt;
  AdminDeployment.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      status = json['status'] as String,
      commit = json['commit'] as String?,
      createdAt = DateTime.parse(json['createdAt'] as String);
}

class AdminServiceDeployments {
  final String name;
  final AdminDeployment? latest;
  final AdminDeployment? previous;
  AdminServiceDeployments.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      latest = json['latest'] == null
          ? null
          : AdminDeployment.fromJson(json['latest'] as Map<String, dynamic>),
      previous = json['previous'] == null
          ? null
          : AdminDeployment.fromJson(json['previous'] as Map<String, dynamic>);
}

class AdminDeploymentStatus {
  final String status;
  final List<AdminServiceDeployments> services;
  AdminDeploymentStatus.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String,
      services = (json['services'] as List)
          .map(
            (s) => AdminServiceDeployments.fromJson(s as Map<String, dynamic>),
          )
          .toList();
}
