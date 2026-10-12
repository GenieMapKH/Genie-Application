import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/widgets/utm_locate_bottom_sheet.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/shared/utils/app_popup.dart';

import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/widgets/property_type_filters.dart';
import 'package:genie/features/home/utils/scanner/document_scanner_service.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

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
          padding: const EdgeInsets.only(left: 16.0, right: 4.0, top: 12.0),
          child: SizedBox(
            height: 350,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
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
                                color: context.colors.surface,
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
                                      context.l10n.homeSearchByAreaRoadVillage,
                                      style: GoogleFonts.inter(
                                        color: context.colors.textMuted,
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
                          onPressed: () => _handleScanClick(context),
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
                    const PropertyTypeFilters(),
                  ],
                ),
                Positioned(
                  top: 117,
                  right: 8.0,
                  child: TactileButton(
                    onPressed: onToggleMapType,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.border,
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
                                ? 'assets/images/homescreen/mapDefault.png'
                                : 'assets/images/homescreen/mapSatellite.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleScanClick(BuildContext context) async {
    final coordinates = await DocumentScannerService.scanCoordinates();

    if (coordinates == null) return; // User cancelled

    if (context.mounted) {
      if (coordinates.isNotEmpty) {
        AppPopup.showSuccess(
          context,
          'Extracted ${coordinates.length} coordinate(s)!',
        );
      } else {
        AppPopup.showError(
          context,
          context.l10n.homeNoCoordinatesFoundPleaseTryAgain,
        );
      }

      final result = await showModalBottomSheet<List<LatLng>>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: false,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            UtmLocateBottomSheet(initialCoordinates: coordinates),
      );

      if (result != null && result.isNotEmpty) {
        onCoordinatesScanned(result);
      }
    }
  }
}
