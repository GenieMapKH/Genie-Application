// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'main_layout.dart';
import 'main_layout_nav.dart';
import 'main_layout_map_clustering.dart';
import 'main_layout_map_details.dart';
import 'main_layout_map_drawing.dart';

extension MainLayoutMapLogic on MainLayoutState {
  Future<void> updateMapOverlays() async {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    final Set<Polyline> newPolylines = {};
    final Set<Polygon> newPolygons = {};

    final double clusterZoomThreshold = 13.0;
    final bool isClusteredView = currentZoom <= clusterZoomThreshold;
    final bool isDetailedView = currentZoom > zoomThreshold;

    List<LatLng> allCentroids = [];
    List<List<LatLng>> detailedProps = [];
    List<bool> detailedPropsIsOwned =
        []; // Track ownership for each detailed property

    // 1. Gather Finalized Property Data
    final List<List<LatLng>> allProps = List.from(finalizedProperties);
    final List<bool> allPropsIsOwned = List.filled(
      finalizedProperties.length,
      true,
      growable: true,
    );

    final backendPropsAsync = ref.read(propertiesProvider);
    final publicPropsAsync = ref.read(publicPropertiesProvider);

    final Map<String, PropertyModel> combinedMap = {};
    final Set<String> myPropertyIds = {};

    if (publicPropsAsync.hasValue) {
      for (final p in publicPropsAsync.value!) {
        combinedMap[p.id] = p;
      }
    }

    if (backendPropsAsync.hasValue) {
      for (final p in backendPropsAsync.value!) {
        combinedMap[p.id] =
            p; // Personal properties overwrite public ones if there's overlap
        myPropertyIds.add(p.id);
      }
    }

    for (final p in combinedMap.values) {
      final bool isOwned = myPropertyIds.contains(p.id);
      if (p.boundaryPoints.isNotEmpty) {
        allProps.add(p.boundaryPoints);
        allPropsIsOwned.add(isOwned);
      } else if (p.lat != null && p.lng != null) {
        allCentroids.add(LatLng(p.lat!, p.lng!));
      }
    }

    for (int pIndex = 0; pIndex < allProps.length; pIndex++) {
      final List<LatLng> propPoints = allProps[pIndex];
      final bool isOwned = allPropsIsOwned[pIndex];

      if (propPoints.length >= 3) {
        double sumLat = 0, sumLng = 0;
        for (var p in propPoints) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final LatLng centroid = LatLng(
          sumLat / propPoints.length,
          sumLng / propPoints.length,
        );
        allCentroids.add(centroid);
        detailedProps.add(propPoints);
        detailedPropsIsOwned.add(isOwned);
      }
    }

    // 2. Render Existing Properties based on Zoom Level
    if (isClusteredView) {
      // Level 1: Province Clustering (Snap to nearest province center)
      renderClusteredView(allCentroids, newMarkers);
    } else if (isDetailedView) {
      // Level 3: Detailed Property Polygons + Text
      await renderDetailedView(detailedProps, detailedPropsIsOwned, newPolygons, newMarkers);
    } else {
      // Level 2: Individual Green Dots
      renderIndividualDotsView(allCentroids, newMarkers);
    }

    // 3. Render Drawing Layer
    if (isDrawing) {
      await renderDrawingLayer(newPolygons, newMarkers, newPolylines);
    }

    if (mounted) {
      setState(() {
        markers = newMarkers;
        polylines = newPolylines;
        polygons = newPolygons;
      });
    }
  }

  void closePolygonForEditing() {
    if (drawnPoints.length < 3) return;

    setState(() {
      isEditingPolygon = true;
    });
    updateMapOverlays();
  }

  Future<void> showAddPropertyForm() async {
    if (drawnPoints.length < 3) return;

    final token = await AuthStorage.getAccessToken();
    if (token == null) {
      if (mounted) {
        showLoginRequiredDialog(context);
      }
      return;
    }

    final measurements = calculateMeasurements(drawnPoints);
    final double area = measurements?.area ?? 0.0;
    final pointsCopy = List<LatLng>.from(drawnPoints);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPropertyPage(boundaryPoints: pointsCopy, propertyArea: area),
      ),
    ).then((result) {
      if (result is PropertyModel) {
        setState(() {
          isDrawing = false;
          isEditingPolygon = false;
          selectedVertexIndex = null;
          // canDraw = false;
          finalizedProperties.add(pointsCopy);
          drawnPoints.clear();
          backupPoints = null;
        });
        updateMapOverlays();
        if (result.status == 'Active') {
          setState(() {
            previousIndex = currentIndex;
            currentIndex = 3;
          });
        }
      }
    });
  }
}
