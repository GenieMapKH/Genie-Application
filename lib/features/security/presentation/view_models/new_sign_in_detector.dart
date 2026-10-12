import 'package:genie/features/security/data/known_devices_storage.dart';
import 'package:genie/features/security/data/models/device_session.dart';
import 'package:genie/features/security/data/repositories/session_repository.dart';

/// Notices when another device signs in to the account, so its owner hears
/// about it on the devices they already use. No UI.
///
/// It compares the server's device list with the devices this phone has
/// already shown. The server also emails the owner; this covers accounts
/// without an email and people who do not read theirs.
class NewSignInDetector {
  final SessionRepository _sessions;
  final KnownDevicesStorage _known;

  NewSignInDetector(this._sessions, this._known);

  /// The devices that signed in since the user was last shown the list.
  ///
  /// Empty the first time this device looks: everything signed in by then
  /// was there before this device, so there is nothing new to report. The
  /// result is reported again next time until [acknowledge] is called.
  Future<List<DeviceSession>> check(String userId) async {
    final devices = await _sessions.fetchSessions();
    final known = await _known.read(userId);
    if (known == null) {
      await _remember(userId, devices);
      return const [];
    }

    final unseen = [
      for (final session in devices.others)
        if (!known.contains(session.id)) session,
    ];
    // Nothing new: forget the devices that have signed out since.
    if (unseen.isEmpty) await _remember(userId, devices);
    return unseen;
  }

  /// The user has seen [devices]: do not report them again.
  Future<void> acknowledge(String userId, List<DeviceSession> devices) async {
    final known = await _known.read(userId) ?? const <String>{};
    await _known.write(userId, {
      ...known,
      for (final device in devices) device.id,
    });
  }

  Future<void> _remember(String userId, DeviceList devices) {
    return _known.write(userId, {
      for (final session in devices.sessions) session.id,
    });
  }
}
