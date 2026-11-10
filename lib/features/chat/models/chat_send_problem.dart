/// Why a message could not be sent. The chat screen says it in the user's
/// language; the layers below only name it.
enum ChatSendProblem {
  signedOut,
  noConnection,

  /// The server refused the message for a reason it did not name.
  rejected,

  /// The server allows a few messages a second.
  tooFast,

  /// One of the two has blocked the other.
  blocked,

  fileTooLarge,
  uploadFailed,
  failed,
}
