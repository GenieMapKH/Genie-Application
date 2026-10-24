import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/nearby_route.dart';
import 'package:genie/features/property/data/repositories/nearby_route_repository.dart';

final nearbyRouteRepositoryProvider = Provider<NearbyRouteRepository>(
  (ref) => NearbyRouteRepository(ref.watch(apiClientProvider)),
);

/// Which road: a listing's [rank]-th nearest place of [category].
typedef NearbyRouteKey = ({String propertyId, String category, int rank});

/// Fetched when the visitor opens a place; the server keeps each road.
final nearbyRouteProvider = FutureProvider.autoDispose
    .family<NearbyRoute, NearbyRouteKey>(
      (ref, key) => ref
          .read(nearbyRouteRepositoryProvider)
          .fetch(key.propertyId, key.category, key.rank),
    );
