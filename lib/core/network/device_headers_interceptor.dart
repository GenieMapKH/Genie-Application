import 'package:dio/dio.dart';

import 'package:genie/core/device/device_description.dart';

/// Tells the sign-in endpoints which device is calling, so the server can
/// list it under "Logged-in devices". Other endpoints do not need it.
class DeviceHeadersInterceptor extends Interceptor {
  static const nameHeader = 'X-Device-Name';
  static const platformHeader = 'X-Device-Platform';

  final DeviceDescriptionReader _reader;

  DeviceHeadersInterceptor(this._reader);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.startsWith('/auth/')) {
      final device = await _reader.read();
      if (device != null) {
        // Header values must be plain ASCII; a device name need not be.
        options.headers[nameHeader] = Uri.encodeComponent(device.name);
        options.headers[platformHeader] = Uri.encodeComponent(device.platform);
      }
    }
    handler.next(options);
  }
}
