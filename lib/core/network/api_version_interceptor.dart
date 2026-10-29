import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the server has said this build's API version is retired.
/// Nothing works until the app is updated, so the app shell shows "Update
/// required" over everything (`lib/app/app.dart`).
final apiVersionRetiredProvider = StateProvider<bool>((ref) => false);

/// Notices the server answering that this build's API version is retired:
/// `410` with `code: api_version_retired`. The request still fails as usual.
class ApiVersionInterceptor extends Interceptor {
  /// What the gateway answers, and the chat socket's handshake error, for a
  /// retired version.
  static const retiredCode = 'api_version_retired';

  final void Function() onRetired;

  ApiVersionInterceptor({required this.onRetired});

  static bool isRetired(Response<dynamic>? response) {
    final data = response?.data;
    return response?.statusCode == 410 &&
        data is Map &&
        data['code'] == retiredCode;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isRetired(err.response)) onRetired();
    handler.next(err);
  }
}
