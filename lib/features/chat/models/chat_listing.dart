/// A listing sent in a chat, as a card: which one, and enough to show it
/// before it is opened. It travels inside the encrypted message, so the
/// server never learns which listing two people talk about.
class ChatListing {
  final String id;
  final String title;

  /// As the card shows it, e.g. `$ 120,000` or `$ 500 / month`.
  final String price;
  final String? imageUrl;

  const ChatListing({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
  });

  /// Longest title kept in a message: a card shows two lines.
  static const _maxTitle = 120;

  /// What an app that cannot draw the card, and a notification, show: the
  /// message's text.
  String get fallbackText => '\u{1F3E0} $title · $price';

  Map<String, Object> toJson() => {
    'id': id,
    'title': title.length > _maxTitle ? title.substring(0, _maxTitle) : title,
    'price': price,
    'image': ?imageUrl,
  };

  /// Null unless [json] is a listing card; only HTTPS pictures are kept.
  static ChatListing? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final price = json['price'];
    if (id is! String || title is! String || price is! String) return null;
    final image = json['image'];
    final imageUri = image is String ? Uri.tryParse(image) : null;
    return ChatListing(
      id: id,
      title: title,
      price: price,
      imageUrl: imageUri != null && imageUri.scheme == 'https' ? image : null,
    );
  }
}
