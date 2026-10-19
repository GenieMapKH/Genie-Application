import 'dart:async';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/call/data/call_tone_player.dart';
import 'package:genie/features/call/models/call_state.dart';

/// Plays the sounds of a call as it moves along: the caller hears the other
/// phone ring until it is answered, both phones chime once the call
/// connects, and the caller hears busy beeps when the call is turned down.
class CallTones {
  /// How the caller hears that the call was turned down.
  static const _turnedDown = {
    CallEndReason.declined,
    CallEndReason.busy,
    CallEndReason.unavailable,
  };

  final CallTonePlayer player;

  CallTones(this.player);

  void update(CallState previous, CallState next) {
    final tone = toneFor(previous, next);
    if (tone != null) {
      _run(() => player.play(tone));
    } else if (previous.phase == CallPhase.outgoing &&
        next.phase != CallPhase.outgoing) {
      _run(player.stop);
    }
  }

  /// The tone that [next] starts, if any.
  static CallTone? toneFor(CallState previous, CallState next) {
    if (next.phase == previous.phase && next.callId == previous.callId) {
      return null;
    }
    return switch (next.phase) {
      CallPhase.outgoing => CallTone.ringback,
      CallPhase.active => CallTone.answered,
      CallPhase.ended
          when next.isCaller && _turnedDown.contains(next.endReason) =>
        CallTone.rejected,
      _ => null,
    };
  }

  void _run(Future<void> Function() action) {
    unawaited(
      action().catchError((Object e, StackTrace stackTrace) {
        AppLogger.error('Call tone not played', e, stackTrace);
      }),
    );
  }
}
