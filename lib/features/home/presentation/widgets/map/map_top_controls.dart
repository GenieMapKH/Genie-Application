import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/presentation/widgets/map/filter/map_filter_button.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_button_icon.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_skin_button.dart';
import 'package:tilomnov/features/home/presentation/widgets/search/home_search_bar.dart';
import 'package:tilomnov/features/home/presentation/widgets/utm/utm_locate_bottom_sheet.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/property_type_filters.dart';
import 'package:tilomnov/features/home/utils/scanner/document_scanner_service.dart';
import 'package:tilomnov/l10n/l10n.dart';

class MapTopControls extends StatelessWidget {
  /// How far the search bar and the type filters reach below the status bar.
  /// Panels on the map start under it.
  static const double contentHeight = 152;

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
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
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
                      // Each button is cropped to its disc, so the gaps here
                      // are the same 8 as between the pills below.
                      spacing: 8,
                      children: [
                        Expanded(
                          child: HomeSearchBar(onOpenProperty: onOpenProperty),
                        ),
                        const MapFilterButton(),
                        // Scan button
                        TactileButton(
                          onPressed: () => _handleScanClick(context),
                          child: Align(
                            widthFactor: MapButtonIcon.discWidthFactor,
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
                  top: 129,
                  right: 0,
                  child: MapSkinButton(
                    currentSkin: currentSkin,
                    onPressed: onToggleMapType,
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
