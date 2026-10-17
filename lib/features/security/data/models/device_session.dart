/// One device signed in to the account, as `GET /auth/sessions` lists it.
class DeviceSession {
  final String id;

  /// e.g. "Samsung SM-G991B". Null when the device did not say.
  final String? deviceName;

  /// e.g. "Android 14".
  final String? platform;

  /// Roughly where the device connects from, e.g. "Phnom Penh, Cambodia".
  /// Null when it could not be worked out (always, on a local network).
  final String? location;
  final String? ipAddress;
  final DateTime signedInAt;

  /// Moves when the device renews its session, so it can be up to about
  /// 15 minutes behind.
  final DateTime lastUsedAt;

  /// True for the device that asked for the list.
  final bool isCurrent;

  const DeviceSession({
    required this.id,
    this.deviceName,
    this.platform,
    this.location,
    this.ipAddress,
    required this.signedInAt,
    required this.lastUsedAt,
    required this.isCurrent,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
      location: json['location'] as String?,
      ipAddress: json['ipAddress'] as String?,
      signedInAt: DateTime.parse(json['signedInAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      isCurrent: json['current'] == true,
    );
  }
}

/// The devices signed in to the account, and what this one may do about
/// the others.
class DeviceList {
  /// Most recently used first.
  final List<DeviceSession> sessions;

  /// False while this device is too new: the server lets a device sign the
  /// others out only after it has been signed in for a day, so that someone
  /// who just got in cannot lock the owner out.
  final bool canSignOutOthers;

  /// When [canSignOutOthers] becomes true. Null if the server does not know
  /// this device's own session.
  final DateTime? canSignOutOthersFrom;

  const DeviceList({
    required this.sessions,
    required this.canSignOutOthers,
    this.canSignOutOthersFrom,
  });

  factory DeviceList.fromJson(Map<String, dynamic> json) {
    final allowedFrom = json['canSignOutOthersFrom'] as String?;
    return DeviceList(
      sessions: [
        for (final session in json['sessions'] as List)
          DeviceSession.fromJson(session as Map<String, dynamic>),
      ],
      canSignOutOthers: json['canSignOutOthers'] == true,
      canSignOutOthersFrom: allowedFrom == null
          ? null
          : DateTime.parse(allowedFrom),
    );
  }

  /// The devices other than the one looking.
  List<DeviceSession> get others => [
    for (final session in sessions)
      if (!session.isCurrent) session,
  ];

  DeviceList without(DeviceSession removed) => DeviceList(
    sessions: [
      for (final session in sessions)
        if (session.id != removed.id) session,
    ],
    canSignOutOthers: canSignOutOthers,
    canSignOutOthersFrom: canSignOutOthersFrom,
  );
}
