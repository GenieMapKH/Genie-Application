// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'main_layout.dart';

extension MainLayoutMapClustering on MainLayoutState {
  void renderClusteredView(List<LatLng> allCentroids, Set<Marker> newMarkers) {
    final List<LatLng> cambodiaProvinces = [
      const LatLng(11.5564, 104.9282), // Phnom Penh
      const LatLng(11.4550, 104.9489), // Kandal
      const LatLng(11.4533, 104.5209), // Kampong Speu
      const LatLng(10.9318, 104.7816), // Takeo
      const LatLng(10.5942, 104.1640), // Kampot
      const LatLng(10.6253, 103.5234), // Sihanoukville
      const LatLng(11.6155, 103.1118), // Koh Kong
      const LatLng(12.5388, 103.9192), // Pursat
      const LatLng(13.0957, 103.2022), // Battambang
      const LatLng(13.5859, 102.9737), // Banteay Meanchey
      const LatLng(14.1818, 103.5166), // Oddar Meanchey
      const LatLng(13.3611, 103.8606), // Siem Reap
      const LatLng(13.8073, 104.9806), // Preah Vihear
      const LatLng(12.7111, 104.9008), // Kampong Thom
      const LatLng(12.2500, 104.6667), // Kampong Chhnang
      const LatLng(11.4886, 105.3253), // Prey Veng
      const LatLng(11.0874, 105.7993), // Svay Rieng
      const LatLng(12.0000, 105.4500), // Kampong Cham
      const LatLng(11.8845, 105.8750), // Tboung Khmum
      const LatLng(12.4833, 106.0167), // Kratie
      const LatLng(13.5258, 105.9688), // Stung Treng
      const LatLng(13.7394, 107.0012), // Ratanakiri
      const LatLng(12.4560, 107.1881), // Mondulkiri
      const LatLng(10.4828, 104.3167), // Kep
      const LatLng(12.8489, 102.6093), // Pailin
    ];

    Set<LatLng> activeClusters = {};

    for (var centroid in allCentroids) {
      LatLng? closestProvince;
      double minDistanceSq = double.infinity;

      for (var province in cambodiaProvinces) {
        final dx = centroid.latitude - province.latitude;
        final dy = centroid.longitude - province.longitude;
        final distSq = dx * dx + dy * dy;

        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          closestProvince = province;
        }
      }

      if (closestProvince != null) {
        activeClusters.add(closestProvince);
      }
    }

    int clusterIndex = 0;
    for (var cluster in activeClusters) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('cluster_${clusterIndex++}'),
          position: cluster,
          icon:
              greenDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  void renderIndividualDotsView(List<LatLng> allCentroids, Set<Marker> newMarkers) {
    for (int i = 0; i < allCentroids.length; i++) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('city_dot_$i'),
          position: allCentroids[i],
          icon:
              greenDotIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }
}
