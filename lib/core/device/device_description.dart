import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:genie/core/logging/app_logger.dart';

/// What this device calls itself. The server shows it to the account owner
/// under "Logged-in devices", so they can tell their devices apart.
class DeviceDescription {
  /// e.g. "Samsung SM-G991B" or "iPhone 15".
  final String name;

  /// e.g. "Android 14" or "iOS 17.5".
  final String platform;

  const DeviceDescription({required this.name, required this.platform});
}

/// Asks the operating system what this device is. Asked once: the answer
/// cannot change while the app runs.
class DeviceDescriptionReader {
  final DeviceInfoPlugin _plugin;
  Future<DeviceDescription?>? _description;

  DeviceDescriptionReader({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  /// Null when the system will not say (an unsupported platform, or a test).
  Future<DeviceDescription?> read() => _description ??= _read();

  Future<DeviceDescription?> _read() async {
    try {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => _android(await _plugin.androidInfo),
        TargetPlatform.iOS => _ios(await _plugin.iosInfo),
        TargetPlatform.windows => _windows(await _plugin.windowsInfo),
        TargetPlatform.macOS => _macOs(await _plugin.macOsInfo),
        TargetPlatform.linux => _linux(await _plugin.linuxInfo),
        TargetPlatform.fuchsia => null,
      };
    } catch (e) {
      // Signing in must still work; the device is then listed without a name.
      AppLogger.error('Could not read the device description', e);
      return null;
    }
  }

  DeviceDescription _android(AndroidDeviceInfo info) => DeviceDescription(
    name: brandedModelName(info.manufacturer, info.model),
    platform: 'Android ${info.version.release}',
  );

  DeviceDescription _ios(IosDeviceInfo info) => DeviceDescription(
    name: info.modelName,
    platform: '${info.systemName} ${info.systemVersion}',
  );

  DeviceDescription _windows(WindowsDeviceInfo info) =>
      DeviceDescription(name: info.computerName, platform: info.productName);

  DeviceDescription _macOs(MacOsDeviceInfo info) => DeviceDescription(
    name: info.computerName,
    platform: 'macOS ${info.osRelease}',
  );

  DeviceDescription _linux(LinuxDeviceInfo info) =>
      DeviceDescription(name: info.name, platform: info.prettyName);
}

/// "samsung" + "SM-G991B" becomes "Samsung SM-G991B"; a model that already
/// starts with its maker ("Google Pixel 8") is left as it is.
@visibleForTesting
String brandedModelName(String manufacturer, String model) {
  final maker = manufacturer.trim();
  final name = model.trim();
  if (maker.isEmpty || name.toLowerCase().startsWith(maker.toLowerCase())) {
    return name;
  }
  return '${maker[0].toUpperCase()}${maker.substring(1)} $name';
}
