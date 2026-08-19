import '../models/property_model.dart';

class PropertyRepository {
  // Global dummy state for prototype
  static final List<PropertyModel> myProperties = [];

  static void addProperty(PropertyModel property) {
    myProperties.insert(0, property); // Add to beginning (newest first)
  }

  static List<PropertyModel> getPropertiesByStatus(String status) {
    return myProperties.where((p) => p.status == status).toList();
  }
}
