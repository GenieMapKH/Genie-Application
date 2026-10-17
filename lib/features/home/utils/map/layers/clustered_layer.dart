import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zoomed-out view: one dot per province that has listings.
abstract final class ClusteredLayer {
  static const _provinceCenters = [
    LatLng(11.5564, 104.9282), // Phnom Penh
    LatLng(11.4550, 104.9489), // Kandal
    LatLng(11.4533, 104.5209), // Kampong Speu
    LatLng(10.9318, 104.7816), // Takeo
    LatLng(10.5942, 104.1640), // Kampot
    LatLng(10.6253, 103.5234), // Sihanoukville
    LatLng(11.6155, 103.1118), // Koh Kong
    LatLng(12.5388, 103.9192), // Pursat
    LatLng(13.0957, 103.2022), // Battambang
    LatLng(13.5859, 102.9737), // Banteay Meanchey
    LatLng(14.1818, 103.5166), // Oddar Meanchey
    LatLng(13.3611, 103.8606), // Siem Reap
    LatLng(13.8073, 104.9806), // Preah Vihear
    LatLng(12.7111, 104.9008), // Kampong Thom
    LatLng(12.2500, 104.6667), // Kampong Chhnang
    LatLng(11.4886, 105.3253), // Prey Veng
    LatLng(11.0874, 105.7993), // Svay Rieng
    LatLng(12.0000, 105.4500), // Kampong Cham
    LatLng(11.8845, 105.8750), // Tboung Khmum
    LatLng(12.4833, 106.0167), // Kratie
    LatLng(13.5258, 105.9688), // Stung Treng
    LatLng(13.7394, 107.0012), // Ratanakiri
    LatLng(12.4560, 107.1881), // Mondulkiri
    LatLng(10.4828, 104.3167), // Kep
    LatLng(12.8489, 102.6093), // Pailin
  ];

  static void build(
    List<LatLng> allCentroids,
    Set<Marker> markers,
    BitmapDescriptor? greenDotIcon,
  ) {
    final activeProvinces = <LatLng>{
      for (final centroid in allCentroids) _nearestProvince(centroid),
    };

    var index = 0;
    for (final province in activeProvinces) {
      markers.add(
        Marker(
          markerId: MarkerId('cluster_${index++}'),
          position: province,
          icon:
              greenDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  /// Straight-line distance on raw degrees is accurate enough at this scale.
  static LatLng _nearestProvince(LatLng point) {
    var nearest = _provinceCenters.first;
    var nearestDistanceSq = double.infinity;

    for (final province in _provinceCenters) {
      final dLat = point.latitude - province.latitude;
      final dLng = point.longitude - province.longitude;
      final distanceSq = dLat * dLat + dLng * dLng;
      if (distanceSq < nearestDistanceSq) {
        nearestDistanceSq = distanceSq;
        nearest = province;
      }
    }
    return nearest;
  }
}
