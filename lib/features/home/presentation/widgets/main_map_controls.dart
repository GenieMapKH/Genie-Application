import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/home/presentation/widgets/map_top_controls.dart';
import 'package:genie/features/home/presentation/widgets/map_floating_menu.dart';
import 'package:genie/features/home/presentation/widgets/drawing_controls_panel.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/home/presentation/widgets/property_carousel.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class MainMapControls extends ConsumerWidget {
  final VoidCallback onGoToCurrentPosition;
  final void Function(List<LatLng>) onAnimateToCoordinates;
  final VoidCallback onAddPinToCenter;
  final VoidCallback onSavePropertySuccess;

  const MainMapControls({
    super.key,
    required this.onGoToCurrentPosition,
    required this.onAnimateToCoordinates,
    required this.onAddPinToCenter,
    required this.onSavePropertySuccess,
  });

  /// Resting offset above the bottom nav bar.
  static const double _baseBottom = 110.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapStateProvider);
    final isCardVisible = ref.watch(propertyCarouselProvider).isVisible;

    // Lift the floating buttons above the property card when it slides in.
    final double sideButtonBottom = isCardVisible
        ? _baseBottom + PropertyCarousel.height - 24
        : _baseBottom;

    return Stack(
      children: [
        // Top Search Bar and Filters
        if (!mapState.isDrawing)
          MapTopControls(
            currentSkin: mapState.currentSkin,
            onToggleMapType: () =>
                ref.read(mapStateProvider.notifier).toggleSkin(),
            onCoordinatesScanned: (result) {
              ref
                  .read(mapStateProvider.notifier)
                  .startDrawing(initialPoints: result);
              onAnimateToCoordinates(result);
            },
          ),

        // Plus Icon and Animated Menu (Bottom Left)
        if (!mapState.isDrawing)
          MapFloatingMenu(
            bottom: sideButtonBottom,
            onDrawPressed: () =>
                ref.read(mapStateProvider.notifier).startDrawing(),
            onCoordinatesScanned: (result) {
              ref
                  .read(mapStateProvider.notifier)
                  .startDrawing(initialPoints: result);
              onAnimateToCoordinates(result);
            },
          ),

        // Current Position Icon (Bottom Right)
        if (!mapState.isDrawing)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: const Cubic(0.16, 1.0, 0.3, 1.0),
            right: 0,
            bottom: sideButtonBottom,
            child: TactileButton(
              onPressed: onGoToCurrentPosition,
              child: SvgPicture.asset(
                'assets/icons/current_position.svg',
                width: 76,
                height: 76,
              ),
            ),
          ),

        // Drawing UI Controls
        if (mapState.isDrawing)
          DrawingControlsPanel(
            isEditingPolygon: mapState.isEditingPolygon,
            onRevertPressed: () {
              if (mapState.isEditingPolygon) {
                if (mapState.selectedVertexIndex != null &&
                    mapState.drawnPoints.length > 3) {
                  ref
                      .read(mapStateProvider.notifier)
                      .removeVertex(mapState.selectedVertexIndex!);
                }
              } else {
                ref.read(mapStateProvider.notifier).removeLastPoint();
              }
            },
            onDeletePressed: () =>
                ref.read(mapStateProvider.notifier).clearDrawing(),
            onCancelPressed: () =>
                ref.read(mapStateProvider.notifier).cancelDrawing(),
            onSavePressed: () {
              if (mapState.drawnPoints.length >= 3) {
                _showAddPropertyForm(context, ref, mapState.drawnPoints);
              } else {
                ref.read(mapStateProvider.notifier).clearDrawing();
              }
            },
            onAddPinPressed: onAddPinToCenter,
          ),
      ],
    );
  }

  Future<void> _showAddPropertyForm(
    BuildContext context,
    WidgetRef ref,
    List<LatLng> drawnPoints,
  ) async {
    final token = await AuthStorage.getAccessToken();
    if (token == null) {
      if (context.mounted) {
        _showLoginRequiredDialog(context);
      }
      return;
    }

    final measurements = calculateMeasurements(drawnPoints);
    final double area = measurements?.area ?? 0.0;
    final pointsCopy = List<LatLng>.from(drawnPoints);

    if (!context.mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPropertyPage(boundaryPoints: pointsCopy, propertyArea: area),
      ),
    );

    if (result != null) {
      ref.read(mapStateProvider.notifier).finalizeDrawing();
      onSavePropertySuccess();
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            context.l10n.loginRequiredTitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context.l10n.loginRequiredMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.commonCancel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
              child: Text(
                context.l10n.loginRequiredAction,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
