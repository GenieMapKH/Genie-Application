import 'package:tilomnov/core/config/app_config.dart';

/// The public web page of listing [propertyId]: what its QR code and shared
/// links open. Anyone can view it there without the app.
Uri propertyShareLink(String propertyId) =>
    Uri.parse('${AppConfig.webBaseUrl}/property/$propertyId');
