import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../utils/ocr_parser.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/utils/app_popup.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:utm/utm.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UtmLocateBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>>? initialCoordinates;
  
  const UtmLocateBottomSheet({super.key, this.initialCoordinates});

  @override
  State<UtmLocateBottomSheet> createState() => _UtmLocateBottomSheetState();
}

class _UtmLocateBottomSheetState extends State<UtmLocateBottomSheet> with SingleTickerProviderStateMixin {
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
    
    if (widget.initialCoordinates != null && widget.initialCoordinates!.isNotEmpty) {
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

    _slideAnimation1 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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

    _slideAnimation2 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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

    _slideAnimation3 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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
        IOSUiSettings(
          title: 'Crop Document',
        ),
      ],
    );
    
    if (croppedFile == null) return; // User canceled crop

    setState(() {
      _isScanning = true;
      _uploadProgress = 0.0;
    });

    try {
      // --- NATIVE ML KIT OCR (MOBILE/DESKTOP) ---
      print('Running native ML Kit OCR...');
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
            AppPopup.showSuccess(context, 'Successfully extracted ${coordinates.length} coordinate(s) natively!');
          } else {
            AppPopup.showInfo(context, 'No coordinates found in the image.');
          }
        });
      }
    } catch (e, stack) {
      print('OCR Error: $e\n$stack');
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
        AppPopup.showError(context, 'Please fill both X and Y coordinates for a row, or leave both empty.');
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
      AppPopup.showError(context, 'Please enter at least 3 coordinates to form a property.');
      return;
    }

    // Pass the parsed LatLng points back to the main layout
    Navigator.of(context).pop(points);
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height to limit modal size
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.95, // Take up 95% of the screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Locate Property',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24), // Balance the back button
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Text
                  FadeTransition(
                    opacity: _fadeAnimation1,
                    child: SlideTransition(
                      position: _slideAnimation1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use UTM from a land document or enter coordinates manually',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 6),
                              Text(
                                'CRS: WGS84 / UTM Zone 48P',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scan Section
                  FadeTransition(
                    opacity: _fadeAnimation2,
                    child: SlideTransition(
                      position: _slideAnimation2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.document_scanner_outlined, size: 40, color: Color(0xFF4B5563)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan UTM from Document',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use camera to detect coordinates',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isScanning ? null : _scanDocument,
                              child: Container(
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      if (_isScanning)
                                        Positioned.fill(
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _uploadProgress,
                                            child: Container(color: const Color(0xFFE5E7EB)),
                                          ),
                                        ),
                                      Center(
                                        child: _isScanning
                                            ? Text(
                                                _uploadProgress < 1.0
                                                    ? 'Processing...'
                                                    : 'Finished',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF374151),
                                                ),
                                              )
                                            : Text(
                                                'Start Scanning',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF374151),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Manual Entry Section
                  FadeTransition(
                    opacity: _fadeAnimation3,
                    child: SlideTransition(
                      position: _slideAnimation3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/keyboard.svg',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enter Coordinates Manually',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type UTM Zone, Easting (X), and Northing (Y).',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF), // Purple color from screenshot
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Enter Coordinates',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Table Headers
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '#',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'X',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Y',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Coordinate Rows
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _coordinateRows.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$index.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: TextField(
                                      controller: _coordinateRows[index]['x'],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        hintText: 'e.g. 485230',
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFFD1D5DB),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: TextField(
                                      controller: _coordinateRows[index]['y'],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        hintText: 'e.g. 1358420',
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFFD1D5DB),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Add Button
                        Center(
                          child: GestureDetector(
                            onTap: _addNewRow,
                            child: Container(
                              width: 60,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: Color(0xFF6B7280), size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100), // Space for bottom button
            ],
              ),
            ),
          ),
          
          // Fixed Preview Button at bottom
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _handlePreview,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Preview',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
