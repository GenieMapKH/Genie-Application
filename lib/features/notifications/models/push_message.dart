/// A push from the notification service, read from its data. Each kind
/// matches one `type` the server sends; anything else is [UnknownPush] and
/// only opens the app.
sealed class PushMessage {
  const PushMessage();

  /// Reads the data of a push. Never throws: a malformed push is unknown.
  factory PushMessage.fromData(Map<String, dynamic> data) {
    String? text(String key) {
      final value = data[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    switch (text('type')) {
      case 'chat_message':
        final senderId = text('senderId');
        if (senderId == null) break;
        return ChatMessagePush(
          senderId: senderId,
          senderName: text('senderName') ?? '',
          messageId: text('messageId'),
        );
      case 'security_sign_in':
        return const SignInAlertPush();
      case 'promotion':
        final promotionId = text('promotionId');
        if (promotionId == null) break;
        return PromotionPush(
          promotionId: promotionId,
          propertyId: text('propertyId'),
          url: _httpsOnly(text('url')),
        );
      case 'call_incoming':
        final callId = text('callId');
        final callerId = text('callerId');
        if (callId == null || callerId == null) break;
        return IncomingCallPush(
          callId: callId,
          callerId: callerId,
          callerName: text('callerName') ?? '',
          sentAt: DateTime.tryParse(text('sentAt') ?? ''),
          answer: text('action') == 'accept',
        );
      case 'call_ended':
        final callId = text('callId');
        if (callId == null) break;
        return CallEndedPush(
          callId: callId,
          callerId: text('callerId') ?? '',
          callerName: text('callerName') ?? '',
          missed: text('missed') == 'true',
        );
    }
    return const UnknownPush();
  }

  /// A link from a push is only ever opened if it is a web page over HTTPS.
  static Uri? _httpsOnly(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }
}

/// Someone sent a chat message. Its text is end-to-end encrypted: only the
/// open app can read it.
class ChatMessagePush extends PushMessage {
  final String senderId;
  final String senderName;
  final String? messageId;

  const ChatMessagePush({
    required this.senderId,
    required this.senderName,
    this.messageId,
  });
}

/// Another device signed in to this account.
class SignInAlertPush extends PushMessage {
  const SignInAlertPush();
}

/// An offer sent by the app's team. Opens a listing, else a web page.
class PromotionPush extends PushMessage {
  final String promotionId;
  final String? propertyId;
  final Uri? url;

  const PromotionPush({required this.promotionId, this.propertyId, this.url});
}

/// Someone is calling.
class IncomingCallPush extends PushMessage {
  final String callId;
  final String callerId;
  final String callerName;

  /// When the server rang; an old push for a call long over is ignored.
  final DateTime? sentAt;

  /// Accept was tapped on the ringing notification: answer at once.
  final bool answer;

  const IncomingCallPush({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.sentAt,
    this.answer = false,
  });
}

/// A call stopped ringing: answered, cancelled, or missed.
class CallEndedPush extends PushMessage {
  final String callId;
  final String callerId;
  final String callerName;
  final bool missed;

  const CallEndedPush({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.missed,
  });
}

class UnknownPush extends PushMessage {
  const UnknownPush();
}
