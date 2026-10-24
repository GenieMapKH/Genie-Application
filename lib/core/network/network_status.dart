import 'dart:async';

import 'package:flutter/foundation.dart';

/// Whether the server can be reached, as the app's own requests find it:
/// a request that cannot connect makes it offline, any answer from the
/// server makes it online again.
///
/// While offline it checks every [_probeEvery] with [probe], so the app
/// notices the connection is back even when nothing else is being loaded.
class NetworkStatus {
  NetworkStatus._();

  static final NetworkStatus instance = NetworkStatus._();

  static const _probeEvery = Duration(seconds: 15);

  final ValueNotifier<bool> online = ValueNotifier(true);

  /// A cheap request to the server; its outcome reaches [reachable] or
  /// [unreachable] through the API client like any other request.
  Future<void> Function()? probe;

  Timer? _probeTimer;

  void reachable() {
    _probeTimer?.cancel();
    _probeTimer = null;
    online.value = true;
  }

  void unreachable() {
    online.value = false;
    _probeTimer ??= Timer.periodic(_probeEvery, (_) => _runProbe());
  }

  Future<void> _runProbe() async {
    try {
      await probe?.call();
    } on Exception {
      // Still offline: [unreachable] was already told by the API client.
    }
  }
}
