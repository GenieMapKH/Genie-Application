import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/layers/boundary_measurement_markers.dart';
import 'package:tilomnov/features/home/utils/map/layers/layer_geometry.dart';
import 'package:tilomnov/features/home/utils/map/map_camera_focus.dart';
import 'package:tilomnov/features/home/utils/map/map_measurements.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_map_preview_overlays.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Satellite map of the property's boundary, drawn as on the main map: gold
/// outline, numbered corners, side lengths and the area. It can be panned,
/// zoomed and turned to look the plot over; labels with no room are left
/// out and come back on zooming in. Its "View on map" button ([onTap])
/// returns the user to the full map.
class PropertyMapPreview extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback? onTap;

  const PropertyMapPreview({super.key, required this.property, this.onTap});

  @override
  State<PropertyMapPreview> createState() => _PropertyMapPreviewState();
}

class _PropertyMapPreviewState extends State<PropertyMapPreview> {
  static const double _height = 190.0;

  static final Set<Factory<OneSequenceGestureRecognizer>> _mapGestures = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  Set<Marker> _labels = const {};

  /// Whether the area fits on the plot; null until the labels are laid out.
  bool? _areaOnPlot;

  /// The whole zoom level the labels are laid out for.
  double? _labelZoom;
  double _cameraZoom = 0;

  List<LatLng> get _points => widget.property.boundaryPoints;
  bool get _hasBoundary => _points.length >= 3;

  @override
  void didUpdateWidget(PropertyMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.property.boundaryPoints, _points)) {
      // Laid out afresh on the next build, for the new boundary.
      _labelZoom = null;
      _labels = const {};
      _areaOnPlot = null;
    }
  }

  /// Lays the labels out again when the zoom reaches another whole level.
  Future<void> _layOutLabels(double zoom) async {
    final level = zoom.floorToDouble();
    if (!_hasBoundary || level == _labelZoom) return;
    _labelZoom = level;
    final labels = <Marker>{};
    final areaOnPlot = await BoundaryMeasurementMarkers.add(
      index: 0,
      points: _points,
      zoom: zoom,
      markers: labels,
      areaInsideOnly: true,
    );
    // A newer zoom started its own layout meanwhile.
    if (!mounted || _labelZoom != level) return;
    setState(() {
      _labels = labels;
      _areaOnPlot = areaOnPlot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? center = _center();
    if (center == null) return const SizedBox.shrink();

    final double zoom = _hasBoundary
        ? MapCameraFocus.zoomToFit(
            _points,
            MediaQuery.sizeOf(context).width - 32,
            _height,
            padding: 32,
          )
        : MapCameraFocus.pinZoom;
    if (_labelZoom == null) {
      _cameraZoom = zoom;
      _layOutLabels(zoom);
    }

    final measurements = _hasBoundary ? calculateMeasurements(_points) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.propertyMapPreview,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                _buildMap(center, zoom),
                // Off the plot, for a plot with no room for it.
                if (measurements != null && _areaOnPlot == false)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IgnorePointer(
                      child: PropertyMapAreaChip(area: measurements.area),
                    ),
                  ),
                if (widget.onTap != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: PropertyMapViewButton(onPressed: widget.onTap!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.propertyLocationBoundary,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMap(LatLng center, double zoom) {
    // Gold, as on the main map: it reads on the satellite photo.
    final boundaryColor = context.colors.highlight;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: zoom),
      // Every drag on the map moves it, not the sheet around it.
      gestureRecognizers: _mapGestures,
      mapType: MapType.hybrid,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: false,
      onCameraMove: (position) => _cameraZoom = position.zoom,
      onCameraIdle: () => _layOutLabels(_cameraZoom),
      polygons: _hasBoundary
          ? {
              Polygon(
                polygonId: PolygonId('preview_${widget.property.id}'),
                points: _points,
                strokeColor: boundaryColor,
                strokeWidth: 3,
                fillColor: boundaryColor.withValues(alpha: 0.25),
              ),
            }
          : const {},
      markers: _hasBoundary
          ? _labels
          : {
              Marker(
                markerId: MarkerId('preview_pin_${widget.property.id}'),
                position: center,
              ),
            },
    );
  }

  LatLng? _center() {
    if (_hasBoundary) return centroidOf(_points);
    final property = widget.property;
    if (property.lat != null && property.lng != null) {
      return LatLng(property.lat!, property.lng!);
    }
    return null;
  }
}
