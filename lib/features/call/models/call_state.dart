/// Where a call is.
enum CallPhase {
  /// No call.
  idle,

  /// Calling someone; their phone is ringing.
  outgoing,

  /// Someone is calling this phone.
  incoming,

  /// Answered; the two phones are connecting.
  connecting,

  /// Talking.
  active,

  /// Over; shown briefly before the screen closes.
  ended,
}

/// Why a call is over, as the person on this phone should hear it.
enum CallEndReason {
  hungUp,
  declined,

  /// Nobody answered (the caller), or the call was not picked up (the callee).
  noAnswer,
  busy,
  unavailable,
  microphoneDenied,
  connectionLost,
  failed,

  /// Taken on another of this user's devices.
  answeredElsewhere,
}

/// The call on this phone, if any.
class CallState {
  final CallPhase phase;
  final String? callId;
  final String? peerId;
  final String? peerName;

  /// True when this phone placed the call.
  final bool isCaller;
  final bool muted;
  final bool speakerOn;

  /// When the two phones connected: the call's duration counts from here.
  final DateTime? connectedAt;
  final CallEndReason? endReason;

  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.peerId,
    this.peerName,
    this.isCaller = false,
    this.muted = false,
    this.speakerOn = false,
    this.connectedAt,
    this.endReason,
  });

  bool get isIdle => phase == CallPhase.idle;

  /// A call is under way: ringing, connecting or talking.
  bool get isLive => phase != CallPhase.idle && phase != CallPhase.ended;

  CallState copyWith({
    CallPhase? phase,
    bool? muted,
    bool? speakerOn,
    DateTime? connectedAt,
    CallEndReason? endReason,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isCaller: isCaller,
      muted: muted ?? this.muted,
      speakerOn: speakerOn ?? this.speakerOn,
      connectedAt: connectedAt ?? this.connectedAt,
      endReason: endReason ?? this.endReason,
    );
  }
}
