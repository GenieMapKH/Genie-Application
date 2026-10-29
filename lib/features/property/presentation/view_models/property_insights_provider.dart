import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/property/data/models/property_insights.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

/// How the owner's listing is doing; read each time its page opens.
final propertyInsightsProvider = FutureProvider.autoDispose
    .family<PropertyInsights, String>((ref, propertyId) {
      return ref.watch(propertyRepositoryProvider).fetchInsights(propertyId);
    });
