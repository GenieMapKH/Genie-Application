import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/widgets/utm_locate_bottom_sheet.dart';
import 'package:genie/features/home/utils/ocr_parser.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/shared/utils/app_popup.dart';

enum MapSkin { defaultMap, satellite }

class MapTopControls extends StatelessWidget {
  final MapSkin currentSkin;
  final VoidCallback onToggleMapType;
  final void Function(List<LatLng>) onCoordinatesScanned;

  const MapTopControls({
    super.key,
    required this.currentSkin,
    required this.onToggleMapType,
    required this.onCoordinatesScanned,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 4.0,
            top: 12.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Search bar
                  Expanded(
                    child: TactileButton(
                      onPressed: () {
                        // TODO: Handle search action
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/search.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search by area, road, village...',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Filter button
                  TactileButton(
                    onPressed: () {},
                    child: Align(
                      widthFactor: 0.8,
                      child: SvgPicture.asset(
                        'assets/icons/filter.svg',
                        width: 76,
                        height: 68,
                      ),
                    ),
                  ),
                  // Scan button
                  TactileButton(
                    onPressed: () => _handleScan(context),
                    child: Align(
                      widthFactor: 0.8,
                      child: SvgPicture.asset(
                        'assets/icons/scan.svg',
                        width: 76,
                        height: 68,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Second Row: Listing Type and Map Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing Type chip
                  TactileButton(
                    onPressed: () {
                      // TODO: Handle listing type tap
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3E49C7),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cancel,
                            color: Color(0xFF3E49C7),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Listing Type',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3E49C7),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF3E49C7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Map type icon
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TactileButton(
                      onPressed: onToggleMapType,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: AssetImage(
                              currentSkin == MapSkin.satellite
                                  ? 'assets/images/homescreen/mapSatellite.png'
                                  : 'assets/images/homescreen/mapDefault.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleScan(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );
    
    if (image == null) return;
    
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
    
    if (croppedFile == null) return;
    
    if (context.mounted) {
      AppPopup.showInfo(context, 'Processing image...');
    }
    
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(croppedFile.path);
    
    final recognizedText = await textRecognizer.processImage(inputImage);
    final coordinates = OcrParser.parseRecognizedText(recognizedText);
    
    await textRecognizer.close();

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (coordinates.isNotEmpty) {
        AppPopup.showSuccess(context, 'Extracted ${coordinates.length} coordinate(s)!');
      } else {
        AppPopup.showError(context, 'No coordinates found. Please try again.');
      }
      
      final result = await showModalBottomSheet<List<LatLng>>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: false,
        backgroundColor: Colors.transparent,
        builder: (context) => UtmLocateBottomSheet(initialCoordinates: coordinates),
      );
      
      if (result != null && result.isNotEmpty) {
        onCoordinatesScanned(result);
      }
    }
  }
}
