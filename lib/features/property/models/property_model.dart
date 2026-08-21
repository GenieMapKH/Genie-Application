import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyModel {
  final String id;
  final String title;
  final String price;
  final String propertyType;
  final String status; // 'Active', 'Draft', 'Pending', 'Sold'
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<LatLng> boundaryPoints;
  final String? description;
  final int? bedrooms;
  final int? bathrooms;
  final double? landSize;
  final double? buildingSize;
  final double? unitSize;
  final double? lat;
  final double? lng;

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.propertyType,
    required this.status,
    required this.createdAt,
    this.imageUrls = const [],
    this.boundaryPoints = const [],
    this.description,
    this.bedrooms,
    this.bathrooms,
    this.landSize,
    this.buildingSize,
    this.unitSize,
    this.lat,
    this.lng,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    if (json['boundaryPoints'] != null && json['boundaryPoints'] is List) {
      points = (json['boundaryPoints'] as List)
          .map(
            (p) => LatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            ),
          )
          .toList();
    }

    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .map((img) => img['url'] as String)
          .toList();
    }

    return PropertyModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      price: json['price']?.toString() ?? '0',
      propertyType: json['propertyType'] ?? 'Land',
      status: json['status'] ?? 'Draft',
      createdAt: DateTime.parse(json['createdAt']),
      imageUrls: images,
      boundaryPoints: points,
      description: json['description'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      landSize: json['landSize'] != null
          ? double.tryParse(json['landSize'].toString())
          : null,
      buildingSize: json['buildingSize'] != null
          ? double.tryParse(json['buildingSize'].toString())
          : null,
      unitSize: json['unitSize'] != null
          ? double.tryParse(json['unitSize'].toString())
          : null,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': double.tryParse(price) ?? 0,
      'propertyType': propertyType,
      if (description != null) 'description': description,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (landSize != null) 'landSize': landSize,
      if (buildingSize != null) 'buildingSize': buildingSize,
      if (unitSize != null) 'unitSize': unitSize,
    };
  }
}
