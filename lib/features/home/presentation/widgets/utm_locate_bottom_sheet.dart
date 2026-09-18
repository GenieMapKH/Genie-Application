import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../utils/scanner/ocr_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/utils/app_popup.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:utm/utm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'utm/components/utm_sheet_header.dart';
import 'utm/entry/utm_scan_section.dart';
import 'utm/entry/utm_manual_entry.dart';
import 'utm/components/utm_preview_button.dart';

class UtmLocateBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? initialCoordinates;

  const UtmLocateBottomSheet({super.key, this.initialCoordinates});

  @override
  State<UtmLocateBottomSheet> createState() => _UtmLocateBottomSheetState();
}

class _UtmLocateBottomSheetState extends State<UtmLocateBottomSheet>
    with SingleTickerProviderStateMixin {
  final List<Map<String, TextEditingController>> _coordinateRows = [];
  bool _isScanning = false;
  double _uploadProgress = 0.0;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation1;
  late Animation<double> _fadeAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<double> _fadeAnimation2;
  late Animation<Offset> _slideAnimation3;
  late Animation<double> _fadeAnimation3;

  @override
  void initState() {
    super.initState();

    if (widget.initialCoordinates != null &&
        widget.initialCoordinates!.isNotEmpty) {
      for (var coord in widget.initialCoordinates!) {
        _coordinateRows.add({
          'x': TextEditingController(text: coord['x'].toString()),
          'y': TextEditingController(text: coord['y'].toString()),
        });
      }
    } else {
      // Initialize with 6 rows as per the design
      for (int i = 0; i < 6; i++) {
        _coordinateRows.add({
          'x': TextEditingController(),
          'y': TextEditingController(),
        });
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation1 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _fadeAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation2 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _fadeAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation3 =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _fadeAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var row in _coordinateRows) {
      row['x']?.dispose();
      row['y']?.dispose();
    }
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      _coordinateRows.add({
        'x': TextEditingController(),
        'y': TextEditingController(),
      });
    });
  }

  Future<void> _scanDocument([ImageSource source = ImageSource.gallery]) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );

    if (image == null) return; // User canceled camera

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

    if (croppedFile == null) return; // User canceled crop

    setState(() {
      _isScanning = true;
      _uploadProgress = 0.0;
    });

    try {
      // --- NATIVE ML KIT OCR (MOBILE/DESKTOP) ---
      debugPrint('Running native ML Kit OCR...');
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(croppedFile.path);

      final recognizedText = await textRecognizer.processImage(inputImage);
      final coordinates = OcrParser.parseRecognizedText(recognizedText);

      await textRecognizer.close();

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          if (coordinates.isNotEmpty) {
            for (int i = 0; i < coordinates.length; i++) {
              if (i >= _coordinateRows.length) {
                _coordinateRows.add({
                  'x': TextEditingController(),
                  'y': TextEditingController(),
                });
              }
              _coordinateRows[i]['x']!.text = coordinates[i]['x'].toString();
              _coordinateRows[i]['y']!.text = coordinates[i]['y'].toString();
            }
            AppPopup.showSuccess(
              context,
              'Successfully extracted ${coordinates.length} coordinate(s) natively!',
            );
          } else {
            AppPopup.showInfo(context, 'No coordinates found in the image.');
          }
        });
      }
    } catch (e, stack) {
      debugPrint('OCR Error: $e\n$stack');
      if (mounted) {
        AppPopup.showError(context, 'Error scanning document: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _handlePreview() {
    List<LatLng> points = [];

    for (var row in _coordinateRows) {
      final String xText = row['x']!.text.trim();
      final String yText = row['y']!.text.trim();

      if (xText.isEmpty && yText.isEmpty) {
        continue; // Skip empty rows
      }

      if (xText.isEmpty || yText.isEmpty) {
        AppPopup.showError(
          context,
          'Please fill both X and Y coordinates for a row, or leave both empty.',
        );
        return;
      }

      final double? easting = double.tryParse(xText);
      final double? northing = double.tryParse(yText);

      if (easting == null || northing == null) {
        AppPopup.showError(context, 'Coordinates must be valid numbers.');
        return;
      }

      try {
        // Convert UTM to LatLng
        final utm = UTM.fromUtm(
          easting: easting,
          northing: northing,
          zoneNumber: 48,
          zoneLetter: 'P',
        );
        points.add(LatLng(utm.lat, utm.lon));
      } catch (e) {
        AppPopup.showError(context, 'Invalid UTM coordinates: $e');
        return;
      }
    }

    if (points.length < 3) {
      AppPopup.showError(
        context,
        'Please enter at least 3 coordinates to form a property.',
      );
      return;
    }

    // Pass the parsed LatLng points back to the main layout
    Navigator.of(context).pop(points);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const UtmSheetHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UtmScanSection(
                    fadeAnimation1: _fadeAnimation1,
                    slideAnimation1: _slideAnimation1,
                    fadeAnimation2: _fadeAnimation2,
                    slideAnimation2: _slideAnimation2,
                    isScanning: _isScanning,
                    uploadProgress: _uploadProgress,
                    onScanDocument: _scanDocument,
                  ),
                  const SizedBox(height: 24),
                  UtmManualEntry(
                    fadeAnimation: _fadeAnimation3,
                    slideAnimation: _slideAnimation3,
                    coordinateRows: _coordinateRows,
                    onAddRow: _addNewRow,
                  ),
                ],
              ),
            ),
          ),
          UtmPreviewButton(onPreview: _handlePreview),
        ],
      ),
    );
  }
}
