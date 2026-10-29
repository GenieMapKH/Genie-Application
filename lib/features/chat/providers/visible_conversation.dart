import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which conversation is on screen, so a notification about it is not shown
/// on top of it. Set by the conversation screen while it is open.
///
/// A plain holder rather than state: nothing redraws when it changes, so the
/// screen may set and clear it while it is built and torn down.
class VisibleConversation {
  String? _participantId;

  /// The other person of the conversation on screen, if any.
  String? get participantId => _participantId;

  void show(String participantId) => _participantId = participantId;

  /// Clears it, unless another conversation has replaced it meanwhile.
  void hide(String participantId) {
    if (_participantId == participantId) _participantId = null;
  }
}

final visibleConversationProvider = Provider<VisibleConversation>(
  (ref) => VisibleConversation(),
);
