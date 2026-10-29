import 'package:dio/dio.dart';

import 'package:tilomnov/features/chat/data/chat_socket_service.dart';

/// How the two phones describe a connection to each other (WebRTC).
typedef SessionDescription = ({String type, String sdp});
typedef NetworkCandidate = ({
  String candidate,
  String? sdpMid,
  int? sdpMLineIndex,
});

/// What the server says about calls, read from the chat connection.
sealed class CallEvent {
  const CallEvent(this.callId);
  final String callId;

  /// Null for an event this app does not understand.
  static CallEvent? fromSocket(CallSocketEvent event) {
    final data = event.data;
    final callId = data['callId'];
    if (callId is! String) return null;
    String? text(String key) =>
        data[key] is String ? data[key] as String : null;

    return switch (event.event) {
      'call:incoming' when text('callerId') != null => CallIncoming(
        callId,
        callerId: text('callerId')!,
        callerName: text('callerName') ?? '',
      ),
      'call:accepted' => CallAccepted(callId),
      'call:answered-elsewhere' => CallAnsweredElsewhere(callId),
      'call:ended' => CallEnded(callId, reason: text('reason') ?? 'ended'),
      'call:signal' => CallSignal.fromData(callId, data),
      _ => null,
    };
  }
}

class CallIncoming extends CallEvent {
  final String callerId;
  final String callerName;
  const CallIncoming(
    super.callId, {
    required this.callerId,
    required this.callerName,
  });
}

class CallAccepted extends CallEvent {
  const CallAccepted(super.callId);
}

class CallAnsweredElsewhere extends CallEvent {
  const CallAnsweredElsewhere(super.callId);
}

/// `reason`: ended, declined, missed, cancelled or disconnected.
class CallEnded extends CallEvent {
  final String reason;
  const CallEnded(super.callId, {required this.reason});
}

/// An offer, an answer, or a network candidate from the other phone.
class CallSignal extends CallEvent {
  final SessionDescription? description;
  final NetworkCandidate? candidate;

  const CallSignal(super.callId, {this.description, this.candidate});

  static CallSignal? fromData(String callId, Map<String, dynamic> data) {
    final type = data['type'];
    if ((type == 'offer' || type == 'answer') && data['sdp'] is String) {
      return CallSignal(
        callId,
        description: (type: type as String, sdp: data['sdp'] as String),
      );
    }
    if (type == 'candidate' && data['candidate'] is String) {
      return CallSignal(
        callId,
        candidate: (
          candidate: data['candidate'] as String,
          sdpMid: data['sdpMid'] as String?,
          sdpMLineIndex: data['sdpMLineIndex'] as int?,
        ),
      );
    }
    return null;
  }
}

/// The server's answer to a request: null when it agreed, else why not
/// (busy, unavailable, gone, too-many, invalid, failed).
typedef CallRefusal = String?;

/// Talks to the server about calls, over the chat connection.
class CallSignaling {
  final ChatSocketService socket;
  final Dio dio;

  CallSignaling({required this.socket, required this.dio});

  Stream<CallEvent> get events => socket.onCallEvent
      .map(CallEvent.fromSocket)
      .where((event) => event != null)
      .cast<CallEvent>();

  /// Fires every time the connection comes back after being lost.
  Stream<void> get reconnects => socket.onConnected;

  Future<CallRefusal> invite(String callId, String calleeId) =>
      _send('call:invite', {'callId': callId, 'calleeId': calleeId});

  Future<CallRefusal> accept(String callId) =>
      _send('call:accept', {'callId': callId});

  Future<CallRefusal> decline(String callId) =>
      _send('call:decline', {'callId': callId});

  Future<CallRefusal> hangUp(String callId) =>
      _send('call:hangup', {'callId': callId});

  Future<CallRefusal> sendDescription(
    String callId,
    SessionDescription description,
  ) => _send('call:signal', {
    'callId': callId,
    'type': description.type,
    'sdp': description.sdp,
  });

  Future<CallRefusal> sendCandidate(
    String callId,
    NetworkCandidate candidate,
  ) => _send('call:signal', {
    'callId': callId,
    'type': 'candidate',
    'candidate': candidate.candidate,
    'sdpMid': ?candidate.sdpMid,
    'sdpMLineIndex': ?candidate.sdpMLineIndex,
  });

  /// The STUN and TURN servers for one call, as WebRTC wants them.
  Future<List<Map<String, dynamic>>> iceServers() async {
    final response = await dio.get('/chat/calls/ice-servers');
    final servers = (response.data as Map)['iceServers'] as List;
    return [
      for (final server in servers) Map<String, dynamic>.from(server as Map),
    ];
  }

  Future<CallRefusal> _send(String event, Map<String, dynamic> payload) async {
    final ack = await socket.sendCallEvent(event, payload);
    if (ack['status'] == 'ok') return null;
    final reason = ack['reason'];
    return reason is String ? reason : 'failed';
  }
}
