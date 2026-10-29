import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/repositories/nearby_route_repository.dart';
import 'package:tilomnov/features/property/utils/polyline_decoder.dart';

void main() {
  test('decodes the polyline of the Google documentation example', () {
    final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 1e-5));
    expect(points[0].longitude, closeTo(-120.2, 1e-5));
    expect(points[1].latitude, closeTo(40.7, 1e-5));
    expect(points[1].longitude, closeTo(-120.95, 1e-5));
    expect(points[2].latitude, closeTo(43.252, 1e-5));
    expect(points[2].longitude, closeTo(-126.453, 1e-5));
    expect(decodePolyline(''), isEmpty);
  });

  test(
    'asks for the road of one place and reads distance and points',
    () async {
      final dio = Dio();
      late RequestOptions asked;
      dio.httpClientAdapter = _Adapter((options) {
        asked = options;
        return '{"meters":1640,"polyline":"_p~iF~ps|U_ulLnnqC"}';
      });

      final route = await NearbyRouteRepository(dio).fetch('p-1', 'market', 2);

      expect(asked.path, '/public/properties/p-1/nearby/market/2/route');
      expect(route.meters, 1640);
      expect(route.points, hasLength(2));
    },
  );
}

class _Adapter implements HttpClientAdapter {
  final String Function(RequestOptions) body;

  _Adapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body(options),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
