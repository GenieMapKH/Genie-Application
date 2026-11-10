import 'dart:typed_data';

import 'package:gal/gal.dart';

/// Keeps a receipt picture in the phone's photos.
class ReceiptSaver {
  const ReceiptSaver();

  /// False when the user does not allow access to their photos.
  Future<bool> saveToPhotos(Uint8List png, {required String name}) async {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
    await Gal.putImageBytes(png, name: name);
    return true;
  }
}
