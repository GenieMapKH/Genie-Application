import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:genie/features/call/models/call_state.dart';
import 'package:genie/features/call/presentation/call_screen.dart';
import 'package:genie/features/call/providers/call_providers.dart';
import 'package:genie/features/chat/providers/chat_call_starter.dart';
import 'package:genie/features/chat/providers/voice_playback_provider.dart';
import 'package:genie/features/notifications/application/push_notifications_controller.dart';
import 'package:genie/features/notifications/models/push_message.dart';

/// The call button of a conversation.
ChatCallStarter callFromChat(Ref ref) {
  return (participantId, participantName) => ref
      .read(callControllerProvider.notifier)
      .call(participantId, participantName);
}

/// A call push that arrives while the app is open. The chat connection
/// usually rang already; this covers the moment it was reconnecting.
CallPushHandler callPushHandler(Ref ref) {
  return (message) {
    if (message is IncomingCallPush) {
      ref
          .read(callControllerProvider.notifier)
          .ringFromPush(
            callId: message.callId,
            callerId: message.callerId,
            callerName: message.callerName,
            sentAt: message.sentAt,
          );
    }
  };
}

/// A ringing call notification was tapped: show the call, and answer it
/// when Accept was the button tapped.
Future<void> openCallFromPush(Ref ref, IncomingCallPush push) async {
  final controller = ref.read(callControllerProvider.notifier)
    ..ringFromPush(
      callId: push.callId,
      callerId: push.callerId,
      callerName: push.callerName,
      sentAt: push.sentAt,
    );
  if (push.answer) await controller.accept();
}

/// Shows the call screen over everything while a call is under way, and
/// takes it away when the call is over.
class CallScreenPresenter {
  Route<void>? _route;

  void update(GoRouter router, CallState call) {
    final navigator = router.routerDelegate.navigatorKey.currentState;
    if (navigator == null) return;

    if (call.isIdle) {
      final route = _route;
      _route = null;
      if (route != null && route.isActive) navigator.removeRoute(route);
      return;
    }
    if (_route?.isActive ?? false) return;
    final route = _route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const CallScreen(),
    );
    navigator.push(route);
  }
}

final callScreenPresenterProvider = Provider((ref) => CallScreenPresenter());

/// What the app does when the call on this phone changes.
void onCallChanged(WidgetRef ref, GoRouter router, CallState call) {
  ref.read(callScreenPresenterProvider).update(router, call);
  // A voice message playing aloud stops when a call starts.
  if (call.isLive && ref.exists(voicePlaybackProvider)) {
    ref.read(voicePlaybackProvider.notifier).stop();
  }
}
