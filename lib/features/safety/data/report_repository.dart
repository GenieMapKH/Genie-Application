import 'package:dio/dio.dart';

import 'package:tilomnov/core/logging/app_logger.dart';

import 'models/report_reason.dart';

/// Why a report was not sent.
enum ReportFailure {
  /// Too many reports in the last hour.
  tooMany,

  /// The listing or account is gone.
  notFound,
  failed,
}

/// Reporting a listing or an account to the admins (`POST /reports`).
/// Reporting the same thing again while it is open changes nothing.
class ReportRepository {
  final Dio dio;

  ReportRepository(this.dio);

  /// Null when the report was received; otherwise why not.
  Future<ReportFailure?> submit({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) async {
    final trimmed = details?.trim();
    try {
      await dio.post(
        '/reports',
        data: {
          'targetType': target.wire,
          'targetId': targetId,
          'reason': reason.wire,
          if (trimmed != null && trimmed.isNotEmpty) 'details': trimmed,
        },
      );
      return null;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 429:
          return ReportFailure.tooMany;
        case 404:
          return ReportFailure.notFound;
        default:
          AppLogger.error('Sending a report failed', e);
          return ReportFailure.failed;
      }
    }
  }
}
