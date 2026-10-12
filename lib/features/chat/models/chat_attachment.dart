/// A file sent in a chat. The file itself is stored encrypted on the server;
/// this is what travels inside the encrypted message so the other person can
/// fetch and open it. The server never sees any of these fields.
class ChatAttachment {
  /// Where the encrypted file is stored.
  final String path;

  /// One-time key and nonce the file was encrypted with (base64).
  final String key;
  final String nonce;

  final String name;
  final String mimeType;

  /// Size of the original file in bytes.
  final int size;

  const ChatAttachment({
    required this.path,
    required this.key,
    required this.nonce,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  static final _pathFormat = RegExp(
    r'^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}$',
    caseSensitive: false,
  );

  bool get isImage => mimeType.startsWith('image/');

  /// Whether the file is stored under the conversation between these two
  /// people, which is the only place the server lets them read from.
  bool belongsTo({required String senderId, required String recipientId}) =>
      path.startsWith('$senderId/$recipientId/');

  /// Null when [json] is not a complete attachment.
  static ChatAttachment? tryParse(Object? json) {
    if (json is! Map) return null;
    final path = json['path'];
    final key = json['key'];
    final nonce = json['nonce'];
    final name = json['name'];
    final mimeType = json['mime'];
    final size = json['size'];
    if (path is! String ||
        key is! String ||
        nonce is! String ||
        name is! String ||
        mimeType is! String ||
        size is! int ||
        !_pathFormat.hasMatch(path)) {
      return null;
    }
    return ChatAttachment(
      path: path,
      key: key,
      nonce: nonce,
      name: name,
      mimeType: mimeType,
      size: size,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'key': key,
    'nonce': nonce,
    'name': name,
    'mime': mimeType,
    'size': size,
  };

  @override
  bool operator ==(Object other) =>
      other is ChatAttachment && other.path == path && other.key == key;

  @override
  int get hashCode => Object.hash(path, key);
}
