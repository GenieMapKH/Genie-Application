import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/call/models/call_state.dart';

/// Keeps native call controls and background audio in step with the live call.
class NativeCallIntegration {
  static const _channel = MethodChannel('tilomnov/call');
  final Future<void> Function() answer;
  final Future<void> Function() end;
  final Future<void> Function(bool) mute;
  final VoidCallback restore;
  Future<void> _updates = Future.value();

  NativeCallIntegration({
    required this.answer,
    required this.end,
    required this.mute,
    required this.restore,
  }) {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'answer':
          await answer();
        case 'end':
          await end();
        case 'mute':
          await mute(call.arguments == true);
        case 'return':
          restore();
      }
    });
  }

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  void update(
    CallState previous,
    CallState call, {
    required String title,
    required String returnLabel,
  }) {
    if (!_supported ||
        (previous.callId == call.callId &&
            previous.phase == call.phase &&
            previous.muted == call.muted)) {
      return;
    }
    _updates = _updates
        .then(
          (_) => _channel.invokeMethod<void>('update', {
            'id': call.callId,
            'phase': call.phase.name,
            'caller': call.isCaller,
            'name': call.peerName,
            'muted': call.muted,
            'title': title,
            'returnLabel': returnLabel,
          }),
        )
        .catchError((Object e, StackTrace stack) {
          AppLogger.error('Native call controls could not update', e, stack);
        });
  }

  void dispose() {
    if (_supported) _channel.setMethodCallHandler(null);
  }
}
