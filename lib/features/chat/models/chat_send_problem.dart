/// Why a message could not be sent. The chat screen says it in the user's
/// language; the layers below only name it.
enum ChatSendProblem {
  signedOut,
  noConnection,

  /// The server refused the message for a reason it did not name.
  rejected,

  /// The server allows a few messages a second.
  tooFast,

  /// The account has no chat PIN yet, and the server sends nothing without.
  pinRequired,

  /// The other person's key changed; the user accepts it first.
  keyChanged,

  /// This device does not have the chat keys.
  notSetUp,

  /// The other person has not set up secure chat yet.
  peerNotReady,
  fileTooLarge,
  uploadFailed,
  failed,
}
