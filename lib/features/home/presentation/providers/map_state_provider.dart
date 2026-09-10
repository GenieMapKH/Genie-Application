import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapSkin { defaultMap, satellite }

class MapState {
  // View State
  final MapSkin currentSkin;
  final double currentZoom;
  final LatLng? currentMapCenter;

  /// Index into the locally drawn [finalizedProperties] that should show its
  /// measurement overlay. Backend-backed properties are highlighted via
  /// `propertyCarouselProvider` instead, since they have a model to select.
  final int? highlightedLocalPolygon;

  // Drawing State
  final bool isDrawing;
  final bool isEditingPolygon;
  final int? selectedVertexIndex;

  // Data State
  final List<LatLng> drawnPoints;
  final List<LatLng>? backupPoints;
  final List<List<LatLng>> finalizedProperties;

  const MapState({
    this.currentSkin = MapSkin.defaultMap,
    this.currentZoom = 14.4746,
    this.currentMapCenter = const LatLng(11.5564, 104.9282),
    this.highlightedLocalPolygon,
    this.isDrawing = false,
    this.isEditingPolygon = false,
    this.selectedVertexIndex,
    this.drawnPoints = const [],
    this.backupPoints,
    this.finalizedProperties = const [],
  });

  MapState copyWith({
    MapSkin? currentSkin,
    double? currentZoom,
    LatLng? currentMapCenter,
    int? highlightedLocalPolygon,
    bool? isDrawing,
    bool? isEditingPolygon,
    int? selectedVertexIndex,
    List<LatLng>? drawnPoints,
    List<LatLng>? backupPoints,
    List<List<LatLng>>? finalizedProperties,
    bool clearHighlightedLocalPolygon = false,
    bool clearSelectedVertex = false,
    bool clearBackupPoints = false,
  }) {
    return MapState(
      currentSkin: currentSkin ?? this.currentSkin,
      currentZoom: currentZoom ?? this.currentZoom,
      currentMapCenter: currentMapCenter ?? this.currentMapCenter,
      highlightedLocalPolygon: clearHighlightedLocalPolygon
          ? null
          : (highlightedLocalPolygon ?? this.highlightedLocalPolygon),
      isDrawing: isDrawing ?? this.isDrawing,
      isEditingPolygon: isEditingPolygon ?? this.isEditingPolygon,
      selectedVertexIndex: clearSelectedVertex ? null : (selectedVertexIndex ?? this.selectedVertexIndex),
      drawnPoints: drawnPoints ?? this.drawnPoints,
      backupPoints: clearBackupPoints ? null : (backupPoints ?? this.backupPoints),
      finalizedProperties: finalizedProperties ?? this.finalizedProperties,
    );
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void setSkin(MapSkin skin) {
    state = state.copyWith(currentSkin: skin);
  }

  void toggleSkin() {
    state = state.copyWith(
      currentSkin: state.currentSkin == MapSkin.defaultMap
        ? MapSkin.satellite
        : MapSkin.defaultMap
    );
  }

  void updateCamera(LatLng target, double zoom) {
    state = state.copyWith(currentMapCenter: target, currentZoom: zoom);
  }

  void highlightLocalPolygon(int? index) {
    state = state.copyWith(
      highlightedLocalPolygon: index,
      clearHighlightedLocalPolygon: index == null,
    );
  }

  // Drawing Actions
  void startDrawing({List<LatLng>? initialPoints}) {
    state = state.copyWith(
      isDrawing: true,
      isEditingPolygon: initialPoints != null,
      drawnPoints: initialPoints ?? [],
      backupPoints: initialPoints != null ? List.from(initialPoints) : null,
      clearSelectedVertex: true,
      clearHighlightedLocalPolygon: true,
    );
  }

  void cancelDrawing() {
    final List<List<LatLng>> newFinalized = List.from(state.finalizedProperties);
    if (state.backupPoints != null) {
      newFinalized.add(state.backupPoints!);
    }
    
    state = state.copyWith(
      isDrawing: false,
      isEditingPolygon: false,
      drawnPoints: [],
      finalizedProperties: newFinalized,
      clearSelectedVertex: true,
      clearBackupPoints: true,
    );
  }

  void clearDrawing() {
    state = state.copyWith(
      drawnPoints: [],
      isDrawing: state.isEditingPolygon ? false : state.isDrawing,
      isEditingPolygon: state.isEditingPolygon ? false : state.isEditingPolygon,
      clearSelectedVertex: true,
      clearBackupPoints: state.isEditingPolygon,
    );
  }

  void closePolygonForEditing() {
    if (state.drawnPoints.length < 3) return;
    state = state.copyWith(isEditingPolygon: true);
  }

  void addPoint(LatLng point) {
    state = state.copyWith(
      drawnPoints: [...state.drawnPoints, point]
    );
  }

  void removeLastPoint() {
    if (state.drawnPoints.isNotEmpty) {
      final newPoints = List<LatLng>.from(state.drawnPoints)..removeLast();
      state = state.copyWith(drawnPoints: newPoints);
    }
  }

  void removeVertex(int index) {
    if (index >= 0 && index < state.drawnPoints.length) {
      final newPoints = List<LatLng>.from(state.drawnPoints)..removeAt(index);
      state = state.copyWith(
        drawnPoints: newPoints,
        clearSelectedVertex: true,
      );
    }
  }

  void updatePoint(int index, LatLng newPosition) {
    if (index >= 0 && index < state.drawnPoints.length) {
      final newPoints = List<LatLng>.from(state.drawnPoints);
      newPoints[index] = newPosition;
      state = state.copyWith(drawnPoints: newPoints);
    }
  }

  void insertPoint(int index, LatLng point) {
    final newPoints = List<LatLng>.from(state.drawnPoints)..insert(index, point);
    state = state.copyWith(
      drawnPoints: newPoints,
      selectedVertexIndex: index,
    );
  }

  void selectVertex(int? index) {
    state = state.copyWith(
      selectedVertexIndex: index,
      clearSelectedVertex: index == null,
    );
  }

  void editProperty(List<LatLng> propertyPoints) {
    final newFinalized = List<List<LatLng>>.from(state.finalizedProperties)
      ..removeWhere((p) => p.toString() == propertyPoints.toString());
      
    state = state.copyWith(
      drawnPoints: List.from(propertyPoints),
      backupPoints: List.from(propertyPoints),
      finalizedProperties: newFinalized,
      isDrawing: true,
      isEditingPolygon: true,
      clearSelectedVertex: true,
    );
  }

  void finalizeDrawing() {
    final newFinalized = List<List<LatLng>>.from(state.finalizedProperties);
    newFinalized.add(List.from(state.drawnPoints));
    
    state = state.copyWith(
      isDrawing: false,
      isEditingPolygon: false,
      drawnPoints: [],
      finalizedProperties: newFinalized,
      clearSelectedVertex: true,
      clearBackupPoints: true,
    );
  }
}

final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
});
