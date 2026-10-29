import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';

/// Whether this phone's own system interface is drawn in liquid glass, so the
/// app can match it. Everyone else keeps the app's regular, opaque look.
///
/// Glass is offered on iOS 26 or later, and on Xiaomi, Redmi and POCO phones
/// running HyperOS [minHyperOsMajor] or later that are not low-memory models.
class GlassCapability {
  /// The first iOS with Liquid Glass.
  static const minIosMajor = 26;

  /// The first HyperOS with a glass system interface. HyperOS 3 blurs and
  /// tints its bars; HyperOS 4 adds refraction. Ours is a blur, so it
  /// matches both.
  static const minHyperOsMajor = 3;

  /// Turns glass on for any device, to try it out or measure it:
  /// `--dart-define=FORCE_GLASS=true`.
  static const _forced = bool.fromEnvironment('FORCE_GLASS');

  final DeviceInfoPlugin _plugin;

  GlassCapability({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  /// Asked once before the first frame, so the app never starts with one
  /// navigation bar and swaps to the other.
  Future<bool> read() async {
    if (_forced) return true;
    try {
      return switch (defaultTargetPlatform) {
        TargetPlatform.iOS => _ios(await _plugin.iosInfo),
        TargetPlatform.android => _android(await _plugin.androidInfo),
        _ => false,
      };
    } catch (e, st) {
      // The regular look is always safe.
      AppLogger.error('Could not read whether the device uses glass', e, st);
      return false;
    }
  }

  bool _ios(IosDeviceInfo info) =>
      !info.isiOSAppOnMac &&
      (majorVersionOf(info.systemVersion) ?? 0) >= minIosMajor;

  bool _android(AndroidDeviceInfo info) =>
      !info.isLowRamDevice &&
      isXiaomiFamily(info.manufacturer, info.brand) &&
      (hyperOsMajorVersionOf(info.version.incremental) ?? 0) >= minHyperOsMajor;
}

/// "26.0.1" gives 26; null when the version does not start with a number.
@visibleForTesting
int? majorVersionOf(String version) =>
    int.tryParse(version.trim().split('.').first);

/// HyperOS names its builds "OS3.0.4.0.WOCMIXM"; MIUI ("V14.0.5.0...") and
/// every other system give null.
@visibleForTesting
int? hyperOsMajorVersionOf(String incremental) {
  final match = RegExp(r'^OS(\d+)\.').firstMatch(incremental.trim());
  return match == null ? null : int.parse(match.group(1)!);
}

/// Redmi and POCO phones are made by Xiaomi and run the same system; some
/// report the sub-brand only as the brand.
@visibleForTesting
bool isXiaomiFamily(String manufacturer, String brand) {
  const family = {'xiaomi', 'redmi', 'poco'};
  return family.contains(manufacturer.trim().toLowerCase()) ||
      family.contains(brand.trim().toLowerCase());
}

/// [GlassCapability.read], answered before the first frame (see `main.dart`).
final glassCapableDeviceProvider = Provider<bool>((ref) => false);
