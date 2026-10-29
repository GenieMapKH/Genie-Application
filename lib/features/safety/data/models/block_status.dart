/// What the signed-in user sees about blocking another person.
class BlockStatus {
  /// Whether the signed-in user blocked them.
  final bool isBlocked;

  /// False when either has blocked the other. Who blocked whom is not said
  /// to the person blocked.
  final bool canMessage;

  const BlockStatus({required this.isBlocked, required this.canMessage});

  factory BlockStatus.fromJson(Map<String, dynamic> json) {
    return BlockStatus(
      isBlocked: json['isBlocked'] as bool,
      canMessage: json['canMessage'] as bool,
    );
  }
}
