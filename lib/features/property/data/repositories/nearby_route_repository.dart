import 'package:dio/dio.dart';
import 'package:genie/features/property/data/models/nearby_route.dart';
import 'package:genie/features/property/utils/polyline_decoder.dart';

class NearbyRouteRepository {
  final Dio dio;

  NearbyRouteRepository(this.dio);

  /// The road from the listing to its [rank]-th nearest place of [category].
  /// A 404 means the place has no road to it; other failures are rethrown.
  Future<NearbyRoute> fetch(
    String propertyId,
    String category,
    int rank,
  ) async {
    final response = await dio.get(
      '/public/properties/$propertyId/nearby/$category/$rank/route',
    );
    final data = response.data as Map<String, dynamic>;
    return NearbyRoute(
      meters: data['meters'] as int,
      points: decodePolyline(data['polyline'] as String),
    );
  }
}
