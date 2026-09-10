import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:genie/features/home/utils/ocr_parser.dart';

class DocumentScannerService {
  static Future<List<Map<String, dynamic>>?> scanCoordinates() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );

    if (image == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: const Color(0xFF5B5FEF),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop Document'),
      ],
    );

    if (croppedFile == null) return null;

    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(croppedFile.path);

    final recognizedText = await textRecognizer.processImage(inputImage);
    final coordinates = OcrParser.parseRecognizedText(recognizedText);

    await textRecognizer.close();

    return coordinates;
  }
}
