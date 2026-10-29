import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/call/data/call_media.dart';
import 'package:tilomnov/features/call/data/call_signaling.dart';
import 'package:tilomnov/features/call/models/call_state.dart';

/// Runs the one call this phone can be in: placing it, ringing, answering,
/// connecting the audio, and ending it, whoever ends it.
class CallController extends StateNotifier<CallState> {
  /// The server stops a ringing call after 45 s; this is only a safety net.
  static const ringTimeout = Duration(seconds: 50);

  /// How long "Call ended" stays on screen.
  static const endedShownFor = Duration(seconds: 2);

  /// A ringing push older than this is about a call already over.
  static const pushFreshFor = Duration(seconds: 45);

  final CallSignaling signaling;
  final CallMedia Function() newMedia;
  final Future<MicrophoneAccess> Function() requestMicrophone;
  final String Function() newCallId;
  final DateTime Function() _now;

  CallMedia? _media;
  Timer? _ringTimer;
  Timer? _closeTimer;
  final _subscriptions = <StreamSubscription<void>>[];
  final _mediaSubscriptions = <StreamSubscription<void>>[];

  /// Set once the server knows this connection is in the call: from then on
  /// losing the connection ends the call (the server ends it too).
  bool _boundToConnection = false;

  /// Server events are handled one at a time, in order.
  Future<void> _events = Future.value();

  CallController({
    required this.signaling,
    required this.newMedia,
    required this.requestMicrophone,
    required this.newCallId,
    DateTime Function() now = DateTime.now,
  }) : _now = now,
       super(const CallState()) {
    _subscriptions
      ..add(
        signaling.events.listen((event) {
          _events = _events.then((_) => _handle(event)).catchError((
            Object e,
            StackTrace stackTrace,
          ) {
            AppLogger.error('Call event not handled', e, stackTrace);
          });
        }),
      )
      ..add(signaling.reconnects.listen((_) => _onReconnected()));
  }

  /// Calls [peerId]. Does nothing while another call is under way.
  Future<void> call(String peerId, String peerName) async {
    if (state.isLive) return;
    _closeTimer?.cancel();
    final callId = newCallId();
    state = CallState(
      phase: CallPhase.outgoing,
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isCaller: true,
    );

    if (await requestMicrophone() != MicrophoneAccess.granted) {
      return _finish(CallEndReason.microphoneDenied);
    }
    if (!_isCurrent(callId)) return;
    final refusal = await _send(() => signaling.invite(callId, peerId));
    if (!_isCurrent(callId)) return;
    if (refusal != null) {
      return _finish(switch (refusal) {
        'busy' => CallEndReason.busy,
        'unavailable' || 'self' => CallEndReason.unavailable,
        _ => CallEndReason.failed,
      });
    }
    _boundToConnection = true;
    _ringTimer = Timer(ringTimeout, () {
      if (_isCurrent(callId) && state.phase == CallPhase.outgoing) hangUp();
    });
  }

  /// Someone is calling, as a push told a phone that was not connected.
  void ringFromPush({
    required String callId,
    required String callerId,
    required String callerName,
    DateTime? sentAt,
  }) {
    if (sentAt != null && _now().difference(sentAt) > pushFreshFor) return;
    _ring(callId, callerId, callerName);
  }

  /// Answers the ringing call.
  Future<void> accept() async {
    final callId = state.callId;
    if (state.phase != CallPhase.incoming || callId == null) return;
    state = state.copyWith(phase: CallPhase.connecting);

    if (await requestMicrophone() != MicrophoneAccess.granted) {
      await _send(() => signaling.decline(callId));
      return _finish(CallEndReason.microphoneDenied);
    }
    // Ready before answering: the caller sends its offer straight away.
    if (!await _openMedia(callId)) return;
    final refusal = await _send(() => signaling.accept(callId));
    if (!_isCurrent(callId)) return;
    if (refusal != null) {
      return _finish(
        refusal == 'gone' ? CallEndReason.noAnswer : CallEndReason.failed,
      );
    }
    _boundToConnection = true;
  }

  Future<void> decline() async {
    final callId = state.callId;
    if (state.phase != CallPhase.incoming || callId == null) return;
    await _send(() => signaling.decline(callId));
    _finish(CallEndReason.declined);
  }

  Future<void> hangUp() async {
    final callId = state.callId;
    if (!state.isLive || callId == null) return;
    await _send(() => signaling.hangUp(callId));
    _finish(CallEndReason.hungUp);
  }

  Future<void> toggleMute() async {
    if (!state.isLive) return;
    final muted = !state.muted;
    state = state.copyWith(muted: muted);
    await _media?.setMuted(muted);
  }

  Future<void> toggleSpeaker() async {
    if (!state.isLive) return;
    final on = !state.speakerOn;
    state = state.copyWith(speakerOn: on);
    try {
      await _media?.setSpeaker(on);
    } catch (e, stackTrace) {
      // Browsers choose their own output.
      AppLogger.error('Speaker could not be switched', e, stackTrace);
    }
  }

  Future<void> _handle(CallEvent event) async {
    switch (event) {
      case CallIncoming(:final callId, :final callerId, :final callerName):
        _ring(callId, callerId, callerName);
      case CallAccepted(:final callId)
          when _isCurrent(callId) && state.isCaller:
        _ringTimer?.cancel();
        state = state.copyWith(phase: CallPhase.connecting);
        if (!await _openMedia(callId)) return;
        final offer = await _media!.createOffer();
        await _send(() => signaling.sendDescription(callId, offer));
      case CallSignal(:final callId) when _isCurrent(callId):
        await _onSignal(event);
      case CallAnsweredElsewhere(:final callId)
          when _isCurrent(callId) && state.phase == CallPhase.incoming:
        _finish(CallEndReason.answeredElsewhere);
      case CallEnded(:final callId, :final reason) when _isCurrent(callId):
        _finish(switch (reason) {
          'declined' => CallEndReason.declined,
          'missed' || 'cancelled' => CallEndReason.noAnswer,
          'disconnected' => CallEndReason.connectionLost,
          _ => CallEndReason.hungUp,
        });
      default:
        break;
    }
  }

  Future<void> _onSignal(CallSignal signal) async {
    final media = _media;
    final callId = state.callId!;
    if (media == null) return;
    final description = signal.description;
    final candidate = signal.candidate;
    if (description?.type == 'offer' && !state.isCaller) {
      final answer = await media.answer(description!);
      await _send(() => signaling.sendDescription(callId, answer));
    } else if (description?.type == 'answer' && state.isCaller) {
      await media.acceptAnswer(description!);
    } else if (candidate != null) {
      await media.addCandidate(candidate);
    }
  }

  void _ring(String callId, String callerId, String callerName) {
    // One call at a time; the server keeps a second caller out anyway.
    if (state.isLive || callId == state.callId) return;
    _closeTimer?.cancel();
    state = CallState(
      phase: CallPhase.incoming,
      callId: callId,
      peerId: callerId,
      peerName: callerName,
    );
  }

  /// The microphone and the connection for [callId]. False (and the call
  /// over) when they cannot be had.
  Future<bool> _openMedia(String callId) async {
    try {
      final iceServers = await signaling.iceServers();
      final media = _media = newMedia();
      await media.open(iceServers);
      _mediaSubscriptions
        ..add(
          media.candidates.listen(
            (candidate) =>
                _send(() => signaling.sendCandidate(callId, candidate)),
          ),
        )
        ..add(media.connection.listen(_onMediaConnection));
      return _isCurrent(callId);
    } catch (e, stackTrace) {
      AppLogger.error('Call audio could not start', e, stackTrace);
      if (_isCurrent(callId)) {
        await _send(() => signaling.hangUp(callId));
        _finish(CallEndReason.failed);
      }
      return false;
    }
  }

  void _onMediaConnection(MediaConnection connection) {
    if (connection == MediaConnection.connected &&
        state.phase == CallPhase.connecting) {
      state = state.copyWith(phase: CallPhase.active, connectedAt: _now());
    } else if (connection == MediaConnection.lost && state.isLive) {
      hangUp();
    }
  }

  /// The connection to the server dropped and came back: the server ended
  /// any call this connection took part in, so this phone does too.
  void _onReconnected() {
    if (_boundToConnection && state.isLive) {
      _finish(CallEndReason.connectionLost);
    }
  }

  /// Sends a request; a lost connection counts as a refusal.
  Future<CallRefusal> _send(Future<CallRefusal> Function() request) async {
    try {
      return await request();
    } catch (e, stackTrace) {
      AppLogger.error('Call request not delivered', e, stackTrace);
      return 'failed';
    }
  }

  bool _isCurrent(String callId) =>
      mounted && state.callId == callId && state.isLive;

  void _finish(CallEndReason reason) {
    if (!mounted || !state.isLive) return;
    _ringTimer?.cancel();
    _boundToConnection = false;
    _closeMedia();
    state = state.copyWith(phase: CallPhase.ended, endReason: reason);
    _closeTimer?.cancel();
    _closeTimer = Timer(endedShownFor, () {
      if (mounted && state.phase == CallPhase.ended) {
        state = const CallState();
      }
    });
  }

  void _closeMedia() {
    for (final subscription in _mediaSubscriptions) {
      subscription.cancel();
    }
    _mediaSubscriptions.clear();
    final media = _media;
    _media = null;
    unawaited(media?.close());
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _ringTimer?.cancel();
    _closeTimer?.cancel();
    _closeMedia();
    super.dispose();
  }
}
