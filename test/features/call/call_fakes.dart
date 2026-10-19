import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/call/data/call_media.dart';
import 'package:genie/features/call/data/call_signaling.dart';

/// Records what the app asked the server, and lets a test answer.
class FakeCallSignaling extends Fake implements CallSignaling {
  final eventStream = StreamController<CallEvent>.broadcast();
  final reconnectStream = StreamController<void>.broadcast();
  final sent = <String>[];
  final descriptions = <SessionDescription>[];
  final candidates = <NetworkCandidate>[];

  /// What the server answers to each request; null is "ok".
  CallRefusal inviteRefusal;
  CallRefusal acceptRefusal;

  FakeCallSignaling({this.inviteRefusal, this.acceptRefusal});

  @override
  Stream<CallEvent> get events => eventStream.stream;

  @override
  Stream<void> get reconnects => reconnectStream.stream;

  @override
  Future<CallRefusal> invite(String callId, String calleeId) async {
    sent.add('invite $calleeId');
    return inviteRefusal;
  }

  @override
  Future<CallRefusal> accept(String callId) async {
    sent.add('accept');
    return acceptRefusal;
  }

  @override
  Future<CallRefusal> decline(String callId) async {
    sent.add('decline');
    return null;
  }

  @override
  Future<CallRefusal> hangUp(String callId) async {
    sent.add('hangup');
    return null;
  }

  @override
  Future<CallRefusal> sendDescription(
    String callId,
    SessionDescription description,
  ) async {
    descriptions.add(description);
    return null;
  }

  @override
  Future<CallRefusal> sendCandidate(
    String callId,
    NetworkCandidate candidate,
  ) async {
    candidates.add(candidate);
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> iceServers() async => [
    {
      'urls': ['stun:stun.example:19302'],
    },
  ];
}

/// Pretends to connect audio; a test says when it connects or drops.
class FakeCallMedia implements CallMedia {
  final candidateStream = StreamController<NetworkCandidate>.broadcast();
  final connectionStream = StreamController<MediaConnection>.broadcast();
  final steps = <String>[];
  Object? openError;
  bool closed = false;
  bool? muted;
  bool? speaker;

  /// What was set up before what (shared with the signaling log in tests).
  final List<String>? log;

  FakeCallMedia({this.log});

  void _step(String step) {
    steps.add(step);
    log?.add(step);
  }

  @override
  Future<void> open(List<Map<String, dynamic>> iceServers) async {
    if (openError != null) throw openError!;
    _step('open');
  }

  @override
  Stream<NetworkCandidate> get candidates => candidateStream.stream;

  @override
  Stream<MediaConnection> get connection => connectionStream.stream;

  @override
  Future<SessionDescription> createOffer() async {
    _step('offer');
    return (type: 'offer', sdp: 'v=0 offer');
  }

  @override
  Future<SessionDescription> answer(SessionDescription offer) async {
    _step('answer ${offer.sdp}');
    return (type: 'answer', sdp: 'v=0 answer');
  }

  @override
  Future<void> acceptAnswer(SessionDescription answer) async =>
      _step('accept-answer ${answer.sdp}');

  @override
  Future<void> addCandidate(NetworkCandidate candidate) async =>
      _step('candidate ${candidate.candidate}');

  @override
  Future<void> setMuted(bool muted) async => this.muted = muted;

  @override
  Future<void> setSpeaker(bool on) async => speaker = on;

  @override
  Future<void> close() async => closed = true;
}
