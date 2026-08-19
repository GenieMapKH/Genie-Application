import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PropertyModel {
  final String id;
  final String title;
  final String price;
  final String propertyType;
  final String status; // 'Active', 'Draft', 'Pending', 'Sold'
  final DateTime createdAt;
  final List<XFile> photos;
  final List<LatLng> boundaryPoints;

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.propertyType,
    required this.status,
    required this.createdAt,
    required this.photos,
    required this.boundaryPoints,
  });
}
