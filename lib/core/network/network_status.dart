import 'dart:async';

import 'package:flutter/foundation.dart';

/// How well the server can be reached, as the app's own requests find it.
enum ConnectionQuality {
  /// Answers come back in good time.
  good,

  /// Answers come, but slowly: a weak signal or a crowded network.
  weak,

  /// Requests cannot reach the server: no internet, or no signal at all.
  offline,
}

/// The [ConnectionQuality] the app's requests have found: a request that
/// cannot connect makes it offline, any answer ends that. Several slow reads
/// in a row make it weak, a quick read makes it good again.
///
/// While offline it checks every [_probeEvery] with [probe], so the app
/// notices the connection is back even when nothing else is being loaded.
/// Weak lasts [_weakFor] after the last slow read unless a quick one comes.
class NetworkStatus {
  NetworkStatus._();

  static final NetworkStatus instance = NetworkStatus._();

  static const _probeEvery = Duration(seconds: 5);
  static const _weakFor = Duration(seconds: 20);

  /// Slow reads in a row, with no quick one between, before the connection
  /// counts as weak. One slow read is usually the server, or one big answer,
  /// not the line: only a connection that stays very slow says so.
  static const slowReadsForWeak = 3;

  int _slowReads = 0;

  final ValueNotifier<ConnectionQuality> connection = ValueNotifier(
    ConnectionQuality.good,
  );

  bool get isOffline => connection.value == ConnectionQuality.offline;

  /// Whether the server's last answer said it is in trouble (5xx), until a
  /// good answer comes. Lets a screen that was only told "failed" say why.
  bool get serverInTrouble => _serverInTrouble;
  bool _serverInTrouble = false;

  /// A cheap request to the server; its outcome reaches [reachable] or
  /// [unreachable] through the API client like any other request.
  Future<void> Function()? probe;

  Timer? _probeTimer;
  Timer? _weakTimer;

  /// The server answered, quickly or not: no longer offline. Whether the
  /// connection is weak is up to [slow] and [quick]. [status] is the
  /// answer's HTTP status, when known.
  void reachable({int? status}) {
    if (status != null) _serverInTrouble = status >= 500;
    _stopProbing();
    if (isOffline) connection.value = ConnectionQuality.good;
  }

  /// A read was answered in good time: the connection is not weak.
  void quick() {
    _slowReads = 0;
    _endWeak();
    if (connection.value == ConnectionQuality.weak) {
      connection.value = ConnectionQuality.good;
    }
  }

  /// A read has been waiting long for its answer, or got it late. Weak from
  /// the [slowReadsForWeak]th in a row. Does not override offline: only an
  /// answer ends that.
  void slow() {
    if (isOffline) return;
    _slowReads++;
    if (_slowReads < slowReadsForWeak) return;
    connection.value = ConnectionQuality.weak;
    _endWeak();
    _weakTimer = Timer(_weakFor, () {
      _weakTimer = null;
      if (connection.value == ConnectionQuality.weak) {
        connection.value = ConnectionQuality.good;
      }
    });
  }

  void unreachable() {
    _slowReads = 0;
    _endWeak();
    connection.value = ConnectionQuality.offline;
    _probeTimer ??= Timer.periodic(_probeEvery, (_) => _runProbe());
  }

  /// Back to a good connection with nothing counted, between tests.
  @visibleForTesting
  void reset() {
    _stopProbing();
    _endWeak();
    _slowReads = 0;
    _serverInTrouble = false;
    connection.value = ConnectionQuality.good;
  }

  /// Asks the server now, e.g. when the user taps Retry.
  Future<void> checkNow() => _runProbe();

  void _endWeak() {
    _weakTimer?.cancel();
    _weakTimer = null;
  }

  void _stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> _runProbe() async {
    try {
      await probe?.call();
    } on Exception {
      // Still offline: [unreachable] was already told by the API client.
    }
  }
}
