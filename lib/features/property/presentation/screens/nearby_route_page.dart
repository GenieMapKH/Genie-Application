import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/utils/map/map_camera_focus.dart';
import 'package:tilomnov/features/property/data/models/nearby_place.dart';
import 'package:tilomnov/features/property/data/models/nearby_route.dart';
import 'package:tilomnov/features/property/presentation/view_models/nearby_route_providers.dart';
import 'package:tilomnov/features/property/utils/nearby_distance_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';

/// A nearby place marked on the map, with the road to it from the listing.
class NearbyRoutePage extends ConsumerWidget {
  final String propertyId;
  final LatLng origin;
  final NearbyPlace place;

  const NearbyRoutePage({
    super.key,
    required this.propertyId,
    required this.origin,
    required this.place,
  });

  NearbyRouteKey get _key =>
      (propertyId: propertyId, category: place.category, rank: place.rank);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(nearbyRouteProvider(_key));

    return Scaffold(
      appBar: AppBar(title: Text(place.name, overflow: TextOverflow.ellipsis)),
      body: route.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PageLoadFailure(
          error: error,
          message: context.l10n.propertyNearbyRouteCouldNotLoad,
          onRetry: () => ref.invalidate(nearbyRouteProvider(_key)),
        ),
        data: (route) => _RouteMap(origin: origin, place: place, route: route),
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  /// Room kept clear at the bottom for the distance card.
  static const _cardSpace = EdgeInsets.only(bottom: 120);

  final LatLng origin;
  final NearbyPlace place;
  final NearbyRoute route;

  const _RouteMap({
    required this.origin,
    required this.place,
    required this.route,
  });

  LatLng get _destination => LatLng(place.lat, place.lng);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, box) => GoogleMap(
            initialCameraPosition: MapCameraFocus.frame(
              _bounds(),
              box.biggest,
              _cardSpace,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('nearby_route'),
                points: route.points,
                color: context.colors.accent,
                width: 5,
              ),
            },
            markers: {
              Marker(markerId: const MarkerId('origin'), position: origin),
              Marker(
                markerId: const MarkerId('place'),
                position: _destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: InfoWindow(title: place.name),
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: _DistanceCard(place: place, meters: route.meters),
          ),
        ),
      ],
    );
  }

  /// The smallest box holding both ends and the whole road.
  LatLngBounds _bounds() {
    final points = [origin, _destination, ...route.points];
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}

class _DistanceCard extends StatelessWidget {
  final NearbyPlace place;
  final int meters;

  const _DistanceCard({required this.place, required this.meters});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatNearbyDistance(context, meters),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
