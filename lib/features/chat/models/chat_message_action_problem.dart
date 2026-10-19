/// Why a message could not be edited or deleted. The chat screen says it in
/// the user's language.
enum ChatMessageActionProblem {
  /// More than an hour has passed since it was sent.
  editTooLate,
  failed,
}
