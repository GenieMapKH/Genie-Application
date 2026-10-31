import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/presentation/widgets/map/map_top_controls.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_side_buttons.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/drawing_controls_panel.dart';
import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/property_carousel.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/home/utils/map/map_measurements.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

class MainMapControls extends ConsumerWidget {
  final VoidCallback onGoToCurrentPosition;
  final void Function(List<LatLng>) onAnimateToCoordinates;
  final VoidCallback onAddPinToCenter;
  final VoidCallback onSavePropertySuccess;
  final ValueChanged<PropertyModel> onOpenProperty;

  /// Lifts the floating buttons above a results sheet: how much of the
  /// screen's bottom the sheet covers, or 0 when there is none.
  final double searchSheetHeight;

  const MainMapControls({
    super.key,
    required this.onGoToCurrentPosition,
    required this.onAnimateToCoordinates,
    required this.onAddPinToCenter,
    required this.onSavePropertySuccess,
    required this.onOpenProperty,
    this.searchSheetHeight = 0,
  });

  /// Resting offset above the bottom nav bar.
  static const double baseBottom = 110.0;

  /// Width of the round floating buttons on the right.
  static const double buttonSize = 76.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapStateProvider);
    final isCardVisible = ref.watch(propertyCarouselProvider).isVisible;

    // Lift the floating buttons above the property card when it slides in.
    final double sideButtonBottom = isCardVisible
        ? baseBottom + PropertyCarousel.height - 24
        : searchSheetHeight > 0
        ? searchSheetHeight - 4
        : baseBottom;

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
            onOpenProperty: onOpenProperty,
          ),

        // Coordinates, Draw and Current Position (Bottom Right)
        if (!mapState.isDrawing)
          MapSideButtons(
            bottom: sideButtonBottom,
            buttonSize: buttonSize,
            // Drawing is how a listing is posted: a guest is asked to sign
            // in before drawing, not after.
            onDrawPressed: () {
              if (!requireSignIn(context, ref)) return;
              ref.read(mapStateProvider.notifier).startDrawing();
            },
            onCoordinatesScanned: (result) {
              ref
                  .read(mapStateProvider.notifier)
                  .startDrawing(initialPoints: result);
              onAnimateToCoordinates(result);
            },
            onGoToCurrentPosition: onGoToCurrentPosition,
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
              final editing = mapState.editingProperty;
              if (mapState.drawnPoints.length >= 3 && editing != null) {
                _showEditPropertyForm(
                  context,
                  ref,
                  editing,
                  mapState.drawnPoints,
                );
              } else if (mapState.drawnPoints.length >= 3) {
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
    if (!requireSignIn(context, ref)) return;

    final measurements = calculateMeasurements(drawnPoints);
    final double area = measurements?.area ?? 0.0;
    final pointsCopy = List<LatLng>.from(drawnPoints);

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

  /// Opens [property]'s edit form, filled in with everything saved before and
  /// the boundary just redrawn as [drawnPoints].
  Future<void> _showEditPropertyForm(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
    List<LatLng> drawnPoints,
  ) async {
    if (!requireSignIn(context, ref)) return;

    final PropertyModel full;
    try {
      // The map holds a slim copy; the form needs every detail.
      full = await ref.read(propertyDetailProvider(property.id).future);
    } catch (e, stack) {
      AppLogger.error('Opening the listing editor failed', e, stack);
      if (context.mounted) {
        showFailure(
          context,
          error: e,
          fallback: context.l10n.propertyCouldNotOpenEditor,
        );
      }
      return;
    }
    if (!context.mounted) return;

    final saved = await Navigator.push<PropertyModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPropertyPage.edit(
          full,
          boundaryPoints: List<LatLng>.from(drawnPoints),
        ),
      ),
    );
    if (saved == null) return;

    ref.invalidate(propertyDetailProvider(property.id));
    ref.read(mapStateProvider.notifier).finalizeDrawing();
  }
}
