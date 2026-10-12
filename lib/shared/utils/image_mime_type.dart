/// The media type of a picture, from its file name. The image picker does
/// not always say, and storage needs it to serve the file as an image.
String imageMimeTypeOf(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };
}
