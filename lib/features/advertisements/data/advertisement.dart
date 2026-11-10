class Advertisement {
  final String id;
  final String imageUrl;
  final int? width;
  final int? height;
  const Advertisement({
    required this.id,
    required this.imageUrl,
    this.width,
    this.height,
  });
  bool get isPortrait => width != null && height != null && height! > width!;
  factory Advertisement.fromJson(Map<String, dynamic> json) => Advertisement(
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String,
    width: json['width'] as int?,
    height: json['height'] as int?,
  );
}
