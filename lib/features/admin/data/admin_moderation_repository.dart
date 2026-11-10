import 'package:dio/dio.dart';
import 'admin_record.dart';

typedef ModerationPage = ({
  List<AdminRecord> items,
  int? nextOffset,
  int? reportCount,
  int? reporterCount,
});

class AdminModerationRepository {
  final Dio dio;
  const AdminModerationRepository(this.dio);
  Future<ModerationPage> reports({
    String? type,
    String? id,
    String? query,
    int offset = 0,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/moderation/reports${id == null ? '' : '/$type/$id'}',
      queryParameters: {'offset': offset, 'q': ?query},
    );
    final data = response.data!;
    return (
      items: (data['items'] as List)
          .map((row) => AdminRecord(row as Map<String, dynamic>))
          .toList(),
      nextOffset: data['nextOffset'] as int?,
      reportCount: data['reportCount'] as int?,
      reporterCount: data['reporterCount'] as int?,
    );
  }

  Future<void> removeProperty(String id, String reason) => dio
      .post<void>('/admin/properties/$id/remove', data: {'reason': reason})
      .then((_) {});
  Future<void> banUser(String id, String reason) => dio
      .post<void>('/admin/users/$id/ban', data: {'reason': reason})
      .then((_) {});
  Future<void> deleteUser(String id, String reason) => dio
      .delete<void>('/admin/users/$id', data: {'reason': reason})
      .then((_) {});
  Future<void> resolveReport(String id) => dio
      .patch<void>('/reports/admin/$id', data: {'status': 'resolved'})
      .then((_) {});
}
