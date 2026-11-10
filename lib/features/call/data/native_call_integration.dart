import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/call/data/call_notifications.dart';
import 'package:tilomnov/features/call/models/call_state.dart';

/// Keeps native call controls and background audio in step with the live call.
class NativeCallIntegration {
  static const _channel = MethodChannel('tilomnov/call');
  final Future<void> Function() answer;
  final Future<void> Function() end;
  final Future<void> Function(bool) mute;
  final VoidCallback restore;
  Future<void> _updates = Future.value();
  CallState _current = const CallState();
  bool _disposed = false;

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

  /// Browsing from a call shown above Android's keyguard requires unlocking.
  static Future<bool> unlockForNavigation() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _channel.invokeMethod<bool>('unlock') ?? false;
    } catch (e, stack) {
      AppLogger.error('The call screen could not be unlocked', e, stack);
      return false;
    }
  }

  void update(
    CallState previous,
    CallState call, {
    required String title,
    required String returnLabel,
    required String incomingTitle,
    required String acceptLabel,
    required String declineLabel,
    required bool Function() isScreenVisible,
  }) {
    if (!_supported ||
        (previous.callId == call.callId &&
            previous.phase == call.phase &&
            previous.muted == call.muted)) {
      return;
    }
    _current = call;
    _updates = _updates
        .then((_) async {
          if (_disposed || !identical(_current, call)) return;
          Future<void> updateNative() => _channel.invokeMethod<void>('update', {
            'id': call.callId,
            'phase': call.phase.name,
            'caller': call.isCaller,
            'name': call.peerName,
            'muted': call.muted,
            'title': title,
            'returnLabel': returnLabel,
            'screenVisible': isScreenVisible(),
          });
          if (defaultTargetPlatform == TargetPlatform.android) {
            final notifications = CallNotifications();
            if (call.phase == CallPhase.incoming && call.callId != null) {
              await notifications.showIncoming(
                callId: call.callId!,
                title: incomingTitle,
                acceptLabel: acceptLabel,
                declineLabel: declineLabel,
                data: {
                  'type': 'call_incoming',
                  'callId': call.callId,
                  'callerId': call.peerId,
                  'callerName': call.peerName,
                  'sentAt': DateTime.now().toUtc().toIso8601String(),
                },
              );
            } else {
              final callId = call.callId ?? previous.callId;
              if (callId != null) await notifications.cancel(callId);
            }
            if (call.isLive) {
              // A paused engine may not render until the notification opens it.
              // Never hold up cancellation while waiting for that frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_disposed ||
                    _current.callId != call.callId ||
                    _current.phase != call.phase) {
                  return;
                }
                unawaited(
                  updateNative().catchError((Object e, StackTrace stack) {
                    AppLogger.error(
                      'Incoming call screen could not update',
                      e,
                      stack,
                    );
                  }),
                );
              });
              WidgetsBinding.instance.ensureVisualUpdate();
              return;
            }
          }
          await updateNative();
        })
        .catchError((Object e, StackTrace stack) {
          AppLogger.error('Native call controls could not update', e, stack);
        });
  }

  void dispose() {
    _disposed = true;
    if (_supported) _channel.setMethodCallHandler(null);
  }
}
