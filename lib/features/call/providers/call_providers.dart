import 'package:tilomnov/features/call/data/native_call_integration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/call/application/call_controller.dart';
import 'package:tilomnov/features/call/application/call_tones.dart';
import 'package:tilomnov/features/call/data/call_media.dart';
import 'package:tilomnov/features/call/data/call_signaling.dart';
import 'package:tilomnov/features/call/data/call_tone_player.dart';
import 'package:tilomnov/features/call/models/call_state.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/shared/utils/random_uuid.dart';

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

/// A live call can stay connected while the user browses.
final callMinimizedProvider = StateProvider<bool>((ref) => false);

final nativeCallIntegrationProvider = Provider((ref) {
  final integration = NativeCallIntegration(
    answer: () => ref.read(callControllerProvider.notifier).accept(),
    end: () => ref.read(callControllerProvider.notifier).hangUp(),
    mute: (muted) async {
      if (ref.read(callControllerProvider).muted != muted) {
        await ref.read(callControllerProvider.notifier).toggleMute();
      }
    },
    restore: () => ref.read(callMinimizedProvider.notifier).state = false,
  );
  ref.onDispose(integration.dispose);
  return integration;
});
