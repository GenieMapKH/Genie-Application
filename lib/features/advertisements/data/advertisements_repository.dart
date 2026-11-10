import 'package:dio/dio.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'advertisement.dart';

class AdvertisementsRepository {
  final Dio dio;
  final Dio storageDio;
  AdvertisementsRepository(this.dio, {Dio? storageDio})
    : storageDio = storageDio ?? Dio();
  Future<List<Advertisement>> load({bool admin = false}) async {
    final response = await dio.get<List<dynamic>>(
      admin ? '/admin/ads' : '/public/ads',
    );
    return response.data!
        .map((row) => Advertisement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> upload(PreparedImage image) async {
    final upload = (await dio.post<Map<String, dynamic>>(
      '/admin/ads/uploads',
    )).data!;
    await storageDio.put<void>(
      upload['uploadUrl'] as String,
      data: Stream.fromIterable([image.bytes]),
      options: Options(
        headers: {
          Headers.contentTypeHeader: image.mimeType,
          Headers.contentLengthHeader: image.bytes.length,
        },
      ),
    );
    await dio.post<void>('/admin/ads', data: {'path': upload['path']});
  }

  Future<void> remove(String id) async {
    await dio.delete<void>('/admin/ads/$id');
  }
}
