import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/call/data/call_signaling.dart';

/// How the audio connection between the two phones is doing.
enum MediaConnection { connecting, connected, lost }

/// The audio side of one call: the microphone, and the connection that
/// carries it straight to the other phone. One instance per call.
abstract interface class CallMedia {
  /// Opens the microphone and prepares the connection. Throws when the
  /// microphone cannot be used.
  Future<void> open(List<Map<String, dynamic>> iceServers);

  /// This phone's network candidates, to be sent to the other phone.
  Stream<NetworkCandidate> get candidates;

  Stream<MediaConnection> get connection;

  /// The caller's side: describes the connection it offers.
  Future<SessionDescription> createOffer();

  /// The callee's side: takes the offer and describes its answer.
  Future<SessionDescription> answer(SessionDescription offer);

  /// The caller's side: takes the callee's answer.
  Future<void> acceptAnswer(SessionDescription answer);

  Future<void> addCandidate(NetworkCandidate candidate);

  Future<void> setMuted(bool muted);

  /// Loudspeaker, else the earpiece (phones only).
  Future<void> setSpeaker(bool on);

  /// Ends everything: microphone off, connection closed. Safe to call twice.
  Future<void> close();
}

/// [CallMedia] with WebRTC. Audio goes directly between the phones, through
/// a TURN relay only when no direct path exists; it is encrypted by WebRTC
/// itself (DTLS-SRTP) and never passes through the app's server.
class WebRtcCallMedia implements CallMedia {
  RTCPeerConnection? _connection;
  MediaStream? _microphone;

  /// Plays the other phone's audio. Needed in a browser; harmless elsewhere.
  RTCVideoRenderer? _remoteAudio;

  /// Candidates that arrived before the other side's description, which
  /// WebRTC must have first.
  final _earlyCandidates = <NetworkCandidate>[];
  bool _hasRemoteDescription = false;
  bool _closed = false;

  final _candidates = StreamController<NetworkCandidate>.broadcast();
  final _state = StreamController<MediaConnection>.broadcast();

  @override
  Stream<NetworkCandidate> get candidates => _candidates.stream;

  @override
  Stream<MediaConnection> get connection => _state.stream;

  @override
  Future<void> open(List<Map<String, dynamic>> iceServers) async {
    _microphone = await navigator.mediaDevices.getUserMedia({
      'audio': {'echoCancellation': true, 'noiseSuppression': true},
      'video': false,
    });
    final connection = _connection = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    });
    for (final track in _microphone!.getAudioTracks()) {
      await connection.addTrack(track, _microphone!);
    }

    final remoteAudio = _remoteAudio = RTCVideoRenderer();
    await remoteAudio.initialize();
    connection
      ..onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteAudio.srcObject = event.streams.first;
        }
      }
      ..onIceCandidate = (candidate) {
        final text = candidate.candidate;
        if (text == null || text.isEmpty || _candidates.isClosed) return;
        _candidates.add((
          candidate: text,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMLineIndex,
        ));
      }
      ..onConnectionState = (state) {
        if (_state.isClosed) return;
        final mapped = switch (state) {
          RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
            MediaConnection.connected,
          RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          RTCPeerConnectionState.RTCPeerConnectionStateClosed =>
            MediaConnection.lost,
          _ => MediaConnection.connecting,
        };
        _state.add(mapped);
      };
  }

  @override
  Future<SessionDescription> createOffer() async {
    final connection = _connection!;
    final offer = await connection.createOffer({'offerToReceiveAudio': true});
    await connection.setLocalDescription(offer);
    return (type: 'offer', sdp: offer.sdp ?? '');
  }

  @override
  Future<SessionDescription> answer(SessionDescription offer) async {
    final connection = _connection!;
    await _setRemote(offer);
    final answer = await connection.createAnswer({'offerToReceiveAudio': true});
    await connection.setLocalDescription(answer);
    return (type: 'answer', sdp: answer.sdp ?? '');
  }

  @override
  Future<void> acceptAnswer(SessionDescription answer) => _setRemote(answer);

  @override
  Future<void> addCandidate(NetworkCandidate candidate) async {
    if (!_hasRemoteDescription) {
      _earlyCandidates.add(candidate);
      return;
    }
    await _connection?.addCandidate(
      RTCIceCandidate(
        candidate.candidate,
        candidate.sdpMid,
        candidate.sdpMLineIndex,
      ),
    );
  }

  @override
  Future<void> setMuted(bool muted) async {
    for (final track in _microphone?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      for (final track in _microphone?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _microphone?.dispose();
      await _connection?.close();
      _remoteAudio?.srcObject = null;
      await _remoteAudio?.dispose();
    } catch (e, stackTrace) {
      AppLogger.error('Call audio did not close cleanly', e, stackTrace);
    } finally {
      await _candidates.close();
      await _state.close();
    }
  }

  Future<void> _setRemote(SessionDescription description) async {
    await _connection!.setRemoteDescription(
      RTCSessionDescription(description.sdp, description.type),
    );
    _hasRemoteDescription = true;
    final early = List.of(_earlyCandidates);
    _earlyCandidates.clear();
    for (final candidate in early) {
      await addCandidate(candidate);
    }
  }
}
