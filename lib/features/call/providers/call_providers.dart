import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/call/application/call_controller.dart';
import 'package:genie/features/call/application/call_tones.dart';
import 'package:genie/features/call/data/call_media.dart';
import 'package:genie/features/call/data/call_signaling.dart';
import 'package:genie/features/call/data/call_tone_player.dart';
import 'package:genie/features/call/models/call_state.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/shared/utils/random_uuid.dart';

/// Calls travel over the chat connection of the signed-in user.
final callSignalingProvider = Provider(
  (ref) => CallSignaling(
    socket: ref.watch(chatSocketServiceProvider),
    dio: ref.watch(apiClientProvider),
  ),
);

/// Makes the audio side of each call; replaced in tests.
final callMediaFactoryProvider = Provider<CallMedia Function()>(
  (ref) => WebRtcCallMedia.new,
);

/// Plays the call's ringback, answered and busy tones; replaced in tests.
final callTonePlayerProvider = Provider<CallTonePlayer>((ref) {
  final player = JustAudioCallTonePlayer();
  ref.onDispose(player.dispose);
  return player;
});

final callTonesProvider = Provider(
  (ref) => CallTones(ref.watch(callTonePlayerProvider)),
);

/// The call on this phone. Rebuilt (and any call ended) when the user
/// changes, with the connection it travels on.
final callControllerProvider = StateNotifierProvider<CallController, CallState>(
  (ref) => CallController(
    signaling: ref.watch(callSignalingProvider),
    newMedia: ref.watch(callMediaFactoryProvider),
    requestMicrophone: ref.watch(microphoneAccessProvider),
    newCallId: randomUuid,
  ),
);
