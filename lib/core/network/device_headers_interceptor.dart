import 'package:dio/dio.dart';

import 'package:tilomnov/core/device/device_description.dart';
import 'package:tilomnov/core/device/sign_in_device_key.dart';

/// Tells the sign-in endpoints which device is calling, so the server can
/// list it under "Logged-in devices" and recognise a device that signed in
/// before. Other endpoints do not need it.
class DeviceHeadersInterceptor extends Interceptor {
  static const nameHeader = 'X-Device-Name';
  static const platformHeader = 'X-Device-Platform';
  static const keyHeader = 'X-Device-Key';

  final DeviceDescriptionReader _reader;
  final SignInDeviceKey _deviceKey;

  DeviceHeadersInterceptor(this._reader, this._deviceKey);

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
      final key = await _deviceKey.read();
      if (key != null) options.headers[keyHeader] = key;
    }
    handler.next(options);
  }
}
