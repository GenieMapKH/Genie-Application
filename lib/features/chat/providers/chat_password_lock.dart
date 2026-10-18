import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

/// Takes the account password right after it was typed (signing in,
/// creating or changing it): the signed-in user's chat keys are restored or
/// locked with it, and it is forgotten again.
///
/// It never fails what it follows: a problem is logged, and chat sorts
/// itself out when it is opened.
class ChatPasswordLock {
  final Ref _ref;

  ChatPasswordLock(this._ref);

  /// [askPin] is asked only for an account that still has a backup PIN, on a
  /// device without its keys: the PIN's last use before the password takes
  /// over. Null when nobody is signed in or something went wrong.
  Future<E2eeSetupResult?> lockWith(
    String password, {
    PinPrompt? askPin,
  }) async {
    try {
      final profile = await _ref.read(userProfileProvider.future);
      if (profile == null) return null;
      return await _ref
          .read(e2eeSetupServiceProvider)
          .initialize(profile.id, password: password, askPin: askPin);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Could not lock the chat keys with the password',
        e,
        stackTrace,
      );
      return null;
    }
  }
}

final chatPasswordLockProvider = Provider<ChatPasswordLock>(
  ChatPasswordLock.new,
);
