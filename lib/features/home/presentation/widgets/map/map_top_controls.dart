import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/widgets/map/filter/map_filter_button.dart';
import 'package:genie/features/home/presentation/widgets/map/map_button_icon.dart';
import 'package:genie/features/home/presentation/widgets/search/home_search_bar.dart';
import 'package:genie/features/home/presentation/widgets/utm/utm_locate_bottom_sheet.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/shared/widgets/buttons/tactile_button.dart';
import 'package:genie/shared/utils/app_popup.dart';

import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/property_type_filters.dart';
import 'package:genie/features/home/utils/scanner/document_scanner_service.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class MapTopControls extends StatelessWidget {
  /// How far the search bar and the type filters reach below the status bar.
  /// Panels on the map start under it.
  static const double contentHeight = 140;

  final MapSkin currentSkin;
  final VoidCallback onToggleMapType;
  final void Function(List<LatLng>) onCoordinatesScanned;
  final ValueChanged<PropertyModel> onOpenProperty;

  const MapTopControls({
    super.key,
    required this.currentSkin,
    required this.onToggleMapType,
    required this.onCoordinatesScanned,
    required this.onOpenProperty,
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
                        Expanded(
                          child: HomeSearchBar(onOpenProperty: onOpenProperty),
                        ),
                        // Each button's picture has 8.4 of space beside its
                        // disc; this makes the search bar's gap the same as
                        // the 16.8 between the two buttons.
                        const SizedBox(width: 8.4),
                        const MapFilterButton(),
                        // Scan button
                        TactileButton(
                          onPressed: () => _handleScanClick(context),
                          child: Align(
                            widthFactor: 0.8,
                            child: MapButtonIcon(
                              asset: 'assets/icons/scan.svg',
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
    final coordinates = await DocumentScannerService.scanCoordinates(
      cropTitle: context.l10n.homeCropDocument,
    );

    if (coordinates == null) return; // User cancelled

    if (context.mounted) {
      if (coordinates.isNotEmpty) {
        AppPopup.showSuccess(
          context,
          context.l10n.homeExtractedCoordinates(coordinates.length),
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
