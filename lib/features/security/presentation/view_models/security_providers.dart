import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/security/data/known_devices_storage.dart';
import 'package:tilomnov/features/security/data/models/device_session.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';
import 'package:tilomnov/features/security/data/repositories/session_repository.dart';
import 'package:tilomnov/features/security/presentation/view_models/account_security_controller.dart';
import 'package:tilomnov/features/security/presentation/view_models/new_sign_in_detector.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(apiClientProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

final accountSecurityControllerProvider = Provider<AccountSecurityController>(
  (ref) => AccountSecurityController(ref.watch(accountRepositoryProvider)),
);

final newSignInDetectorProvider = Provider<NewSignInDetector>(
  (ref) => NewSignInDetector(
    ref.watch(sessionRepositoryProvider),
    KnownDevicesStorage(),
  ),
);

/// The devices signed in to the account. Loaded when the screen opens and
/// dropped when it closes, so the list is never an old one.
final deviceSessionsProvider =
    AsyncNotifierProvider.autoDispose<DeviceSessionsNotifier, DeviceList>(
      DeviceSessionsNotifier.new,
    );

class DeviceSessionsNotifier extends AutoDisposeAsyncNotifier<DeviceList> {
  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  Future<DeviceList> build() => _repository.fetchSessions();

  /// Signs one device out and takes it off the list. False if it failed.
  Future<bool> signOut(DeviceSession session) async {
    try {
      await _repository.signOut(session.id);
    } catch (e) {
      AppLogger.error('Could not sign the device out', e);
      return false;
    }
    final devices = state.valueOrNull;
    if (devices != null) state = AsyncData(devices.without(session));
    return true;
  }

  /// Signs every device out, this one included. False if it failed.
  Future<bool> signOutAll() async {
    try {
      await _repository.signOutAll();
      return true;
    } catch (e) {
      AppLogger.error('Could not sign all devices out', e);
      return false;
    }
  }
}
