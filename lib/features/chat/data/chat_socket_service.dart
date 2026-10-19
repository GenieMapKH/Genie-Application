import 'dart:async';
import 'dart:math';

import 'package:genie/core/config/app_config.dart';
import 'package:genie/core/errors/app_exceptions.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_participant.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/models/conversation_change.dart';
import 'package:genie/features/chat/models/message_deletion.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Thrown when a message could not be handed to the server. [message] is
/// for logs; the user is told [problem] in their language.
class ChatSendException extends AppException {
  final ChatSendProblem problem;

  const ChatSendException(this.problem, [String? message])
    : super(message ?? 'Message not sent');

  /// Names a refusal by what the server said, which is English.
  factory ChatSendException.rejected(Object? reason) {
    final text = reason is String ? reason : '';
    final problem = text.contains('chat PIN')
        ? ChatSendProblem.pinRequired
        : text.contains('too quickly')
        ? ChatSendProblem.tooFast
        : ChatSendProblem.rejected;
    return ChatSendException(problem, text.isEmpty ? null : text);
  }
}

/// A call event the server sent: its name and payload.
typedef CallSocketEvent = ({String event, Map<String, dynamic> data});

/// The real-time connection of one signed-in user. It carries ciphertext
/// both ways and never sees a readable message. Voice calls are signalled
/// over it too (see [onCallEvent]).
class ChatSocketService {
  static const _ackTimeout = Duration(seconds: 10);
  static const _maxRetryDelay = Duration(seconds: 60);

  /// A connection that lasted this long was accepted by the server.
  static const _stableAfter = Duration(seconds: 30);

  /// Reads the current access token; null when signed out. [afterRejection]
  /// is set when the server refused the previous one.
  final Future<String?> Function({bool afterRejection}) readAccessToken;
  final String _url;

  io.Socket? _socket;
  String? _handshakeToken;
  DateTime? _connectedAt;
  int _rejections = 0;
  Timer? _retryTimer;
  bool _disposed = false;

  final _messages = StreamController<EncryptedMessage>.broadcast();
  final _connections = StreamController<void>.broadcast();
  final _presence = StreamController<ChatPresence>.broadcast();
  final _conversationChanges = StreamController<ConversationChange>.broadcast();
  final _editedMessages = StreamController<EncryptedMessage>.broadcast();
  final _deletedMessages = StreamController<MessageDeletion>.broadcast();
  final _callEvents = StreamController<CallSocketEvent>.broadcast();

  /// What the server sends about calls; the call feature reads them.
  static const callEventNames = [
    'call:incoming',
    'call:accepted',
    'call:answered-elsewhere',
    'call:ended',
    'call:signal',
  ];

  ChatSocketService({required this.readAccessToken, String? baseUrl})
    : _url = '${baseUrl ?? AppConfig.apiBaseUrl}/chat';

  /// Messages delivered live: from the other person, or sent by this user
  /// on another device.
  Stream<EncryptedMessage> get onMessage => _messages.stream;

  /// Fires every time the connection is established. Anything that arrived
  /// while offline was not delivered, so listeners reload from the API.
  Stream<void> get onConnected => _connections.stream;

  /// Online/offline changes of the users being watched.
  Stream<ChatPresence> get onPresence => _presence.stream;

  /// Conversations archived, restored or deleted elsewhere.
  Stream<ConversationChange> get onConversationChanged =>
      _conversationChanges.stream;

  /// Messages whose sender changed the text, here or on another device.
  Stream<EncryptedMessage> get onMessageEdited => _editedMessages.stream;

  /// Messages deleted for this user: by them on any device, or by the
  /// sender for everyone.
  Stream<MessageDeletion> get onMessageDeleted => _deletedMessages.stream;

  /// Call events: someone calling, answering, hanging up, or signalling.
  Stream<CallSocketEvent> get onCallEvent => _callEvents.stream;

  /// Sends a call event and returns the server's answer as it is, refusals
  /// included: the call feature reads why. Throws a [ChatSendException]
  /// only when there is no connection or no answer.
  Future<Map<String, dynamic>> sendCallEvent(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = await connect() ? _socket : null;
    if (socket == null) {
      throw const ChatSendException(ChatSendProblem.signedOut);
    }
    try {
      final ack = await socket
          .timeout(_ackTimeout.inMilliseconds)
          .emitWithAckAsync(event, payload);
      return ack is Map ? Map<String, dynamic>.from(ack) : const {};
    } catch (e) {
      AppLogger.error('$event was not acknowledged', e);
      throw const ChatSendException(ChatSendProblem.noConnection);
    }
  }

  /// Opens the connection, or re-opens it when the session token changed.
  /// Returns false when there is no session to connect with.
  Future<bool> connect({bool afterRejection = false}) async {
    if (_disposed) return false;
    final token = await readAccessToken(afterRejection: afterRejection);
    if (token == null || _disposed) return false;

    final socket = _socket ??= _createSocket();
    if (token != _handshakeToken) {
      // The server checks the handshake token on every message and drops
      // the connection once it expires, so reconnect with the new one.
      if (_handshakeToken != null) socket.disconnect();
      _handshakeToken = token;
    }
    if (!socket.active) socket.connect();
    return true;
  }

  /// Sends one encrypted message and returns it as the server stored it.
  /// [id] makes a retry safe: the server stores the same id only once.
  /// [replyToId] is the message it replies to.
  Future<EncryptedMessage> send({
    required String id,
    required String recipientId,
    required String ciphertext,
    required String nonce,
    String? replyToId,
  }) async {
    final ack = await _request('sendMessage', {
      'id': id,
      'recipientId': recipientId,
      'ciphertext': ciphertext,
      'nonce': nonce,
      'replyToId': ?replyToId,
    });
    return EncryptedMessage.fromJson(_asJson(ack['message']));
  }

  /// Whether [userId] is online now, and from then on every change of that
  /// on [onPresence]. Watching ends with the connection, so it is asked
  /// again after each [onConnected].
  Future<ChatPresence> watchPresence(String userId) async {
    final ack = await _request('watchPresence', {'userId': userId});
    return ChatPresence.fromJson(_asJson(ack['presence']));
  }

  void unwatchPresence(String userId) {
    final socket = _socket;
    if (socket != null && socket.connected) {
      socket.emit('unwatchPresence', {'userId': userId});
    }
  }

  /// Emits [event] and returns the server's acknowledgement, or throws a
  /// [ChatSendException] saying why there was none.
  Future<Map<dynamic, dynamic>> _request(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = await connect() ? _socket : null;
    if (socket == null) {
      throw const ChatSendException(ChatSendProblem.signedOut);
    }

    final dynamic ack;
    try {
      // While reconnecting the request waits in the socket's buffer.
      ack = await socket
          .timeout(_ackTimeout.inMilliseconds)
          .emitWithAckAsync(event, payload);
    } catch (e) {
      AppLogger.error('$event was not acknowledged', e);
      throw const ChatSendException(ChatSendProblem.noConnection);
    }

    if (ack is! Map || ack['status'] != 'ok') {
      throw ChatSendException.rejected(ack is Map ? ack['message'] : null);
    }
    return ack;
  }

  Map<String, dynamic> _asJson(dynamic json) {
    if (json is! Map) {
      throw const ChatSendException(
        ChatSendProblem.failed,
        'The server sent an unexpected reply',
      );
    }
    return Map<String, dynamic>.from(json);
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _messages.close();
    _connections.close();
    _presence.close();
    _conversationChanges.close();
    _editedMessages.close();
    _deletedMessages.close();
    _callEvents.close();
  }

  io.Socket _createSocket() {
    final socket = io.io(
      _url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          // Asked on every (re)connection, so a renewed token is picked up.
          .setAuthFn((callback) => callback({'token': _handshakeToken}))
          .build(),
    );

    socket.onConnect((_) {
      AppLogger.debug('Chat socket connected');
      _connectedAt = DateTime.now();
      if (!_connections.isClosed) _connections.add(null);
    });

    socket.on('newMessage', _onNewMessage);
    socket.on('presence', _onPresence);
    socket.on('conversationChanged', _onConversationChanged);
    socket.on('messageEdited', _onMessageEdited);
    socket.on('messageDeleted', _onMessageDeleted);
    for (final event in callEventNames) {
      socket.on(event, (data) => _onCallEvent(event, data));
    }

    // A refused handshake. Network failures are retried by the socket itself.
    socket.onConnectError((error) {
      if (error is Map && error['message'] == 'unauthorized') {
        _reconnectAfterRejection();
      }
    });

    socket.onDisconnect((reason) {
      AppLogger.debug('Chat socket disconnected: $reason');
      if (reason == 'io server disconnect') _reconnectAfterRejection();
    });

    return socket;
  }

  void _onNewMessage(dynamic data) {
    try {
      final message = EncryptedMessage.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (!_messages.isClosed) _messages.add(message);
    } catch (e, stackTrace) {
      AppLogger.error('Ignored a malformed chat message', e, stackTrace);
    }
  }

  void _onPresence(dynamic data) {
    try {
      final presence = ChatPresence.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (!_presence.isClosed) _presence.add(presence);
    } catch (e, stackTrace) {
      AppLogger.error('Ignored a malformed presence update', e, stackTrace);
    }
  }

  void _onConversationChanged(dynamic data) {
    try {
      final change = ConversationChange.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (!_conversationChanges.isClosed) _conversationChanges.add(change);
    } catch (e, stackTrace) {
      AppLogger.error('Ignored a malformed conversation change', e, stackTrace);
    }
  }

  void _onMessageEdited(dynamic data) {
    try {
      final message = EncryptedMessage.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (!_editedMessages.isClosed) _editedMessages.add(message);
    } catch (e, stackTrace) {
      AppLogger.error('Ignored a malformed message edit', e, stackTrace);
    }
  }

  void _onMessageDeleted(dynamic data) {
    try {
      final deletion = MessageDeletion.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (!_deletedMessages.isClosed) _deletedMessages.add(deletion);
    } catch (e, stackTrace) {
      AppLogger.error('Ignored a malformed message deletion', e, stackTrace);
    }
  }

  void _onCallEvent(String event, dynamic data) {
    if (data is! Map || _callEvents.isClosed) return;
    _callEvents.add((event: event, data: Map<String, dynamic>.from(data)));
  }

  /// The server turned this connection away, usually because the token
  /// expired. It does not retry on its own, so try again with a current
  /// token, waiting longer each time the server keeps refusing.
  void _reconnectAfterRejection() {
    if (_disposed) return;

    final connectedAt = _connectedAt;
    _connectedAt = null;
    final wasStable =
        connectedAt != null &&
        DateTime.now().difference(connectedAt) > _stableAfter;
    _rejections = wasStable ? 0 : _rejections + 1;

    final seconds = min(1 << min(_rejections, 6), _maxRetryDelay.inSeconds);
    _handshakeToken = null;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), _retryConnect);
  }

  Future<void> _retryConnect() async {
    try {
      await connect(afterRejection: true);
    } catch (e, stackTrace) {
      AppLogger.error('Chat socket could not reconnect', e, stackTrace);
    }
  }
}
