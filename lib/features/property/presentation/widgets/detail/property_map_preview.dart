import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map_camera_focus.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// Satellite thumbnail of the property's boundary, with the measured area
/// overlaid. Non-interactive: tapping it returns the user to the full map.
class PropertyMapPreview extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;

  const PropertyMapPreview({super.key, required this.property, this.onTap});

  static const double _height = 190.0;

  @override
  Widget build(BuildContext context) {
    final points = property.boundaryPoints;
    final LatLng? center = _center();
    if (center == null) return const SizedBox.shrink();

    final double zoom = points.length >= 3
        ? MapCameraFocus.zoomToFit(
            points,
            MediaQuery.sizeOf(context).width - 32,
            _height,
            padding: 32,
          )
        : MapCameraFocus.pinZoom;

    final measurements = points.length >= 3 ? calculateMeasurements(points) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map Preview',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                // Lite mode keeps this cheap: a static snapshot, no gestures.
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: center, zoom: zoom),
                  liteModeEnabled: true,
                  mapType: MapType.hybrid,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  polygons: points.length >= 3
                      ? {
                          Polygon(
                            polygonId: PolygonId('preview_${property.id}'),
                            points: points,
                            strokeColor: const Color(0xFF4F5BD5),
                            strokeWidth: 2,
                            fillColor:
                                const Color(0xFF4F5BD5).withValues(alpha: 0.2),
                          ),
                        }
                      : const {},
                  markers: points.length >= 3
                      ? const {}
                      : {
                          Marker(
                            markerId: MarkerId('preview_pin_${property.id}'),
                            position: center,
                          ),
                        },
                ),
                if (measurements != null)
                  Center(child: _AreaChip(area: measurements.area)),
                // Transparent tap target above the lite map.
                if (onTap != null)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Location & Boundary',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  LatLng? _center() {
    if (property.boundaryPoints.length >= 3) {
      double sumLat = 0, sumLng = 0;
      for (final point in property.boundaryPoints) {
        sumLat += point.latitude;
        sumLng += point.longitude;
      }
      final count = property.boundaryPoints.length;
      return LatLng(sumLat / count, sumLng / count);
    }
    if (property.lat != null && property.lng != null) {
      return LatLng(property.lat!, property.lng!);
    }
    return null;
  }
}

class _AreaChip extends StatelessWidget {
  final double area;

  const _AreaChip({required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        formatArea(area),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
