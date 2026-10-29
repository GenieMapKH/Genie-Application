import 'package:flutter/widgets.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// 850 -> "850 m", 1640 -> "1.6 km".
String formatNearbyDistance(BuildContext context, int meters) {
  if (meters < 1000) return context.l10n.propertyDistanceM(meters);
  return context.l10n.propertyDistanceKm((meters / 1000).toStringAsFixed(1));
}
