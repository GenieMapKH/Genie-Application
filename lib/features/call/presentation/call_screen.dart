import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/call/models/call_state.dart';
import 'package:genie/features/call/presentation/widgets/call_action_button.dart';
import 'package:genie/features/call/providers/call_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/media/user_avatar.dart';

/// The whole screen while a call rings, connects or goes on. It cannot be
/// left with Back while the call is live: the call must be ended first.
class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    final name = call.peerName ?? '';

    return PopScope(
      canPop: !call.isLive,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(),
                UserAvatar(name: name, avatarUrl: null, radius: 56),
                const SizedBox(height: 24),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _CallStatus(call: call),
                const Spacer(flex: 2),
                switch (call.phase) {
                  CallPhase.incoming => _IncomingActions(
                    onAccept: controller.accept,
                    onDecline: controller.decline,
                  ),
                  CallPhase.outgoing ||
                  CallPhase.connecting ||
                  CallPhase.active => _LiveActions(
                    call: call,
                    onMute: controller.toggleMute,
                    onSpeaker: controller.toggleSpeaker,
                    onHangUp: controller.hangUp,
                  ),
                  CallPhase.idle ||
                  CallPhase.ended => const SizedBox(height: 88),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Calling…", the running time, or why the call ended.
class _CallStatus extends StatefulWidget {
  final CallState call;

  const _CallStatus({required this.call});

  @override
  State<_CallStatus> createState() => _CallStatusState();
}

class _CallStatusState extends State<_CallStatus> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.call.phase == CallPhase.active) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final call = widget.call;
    final text = switch (call.phase) {
      CallPhase.outgoing => l10n.callCalling,
      CallPhase.incoming => l10n.callIncoming,
      CallPhase.connecting => l10n.callConnecting,
      CallPhase.active => _duration(
        DateTime.now().difference(call.connectedAt ?? DateTime.now()),
      ),
      CallPhase.ended => switch (call.endReason) {
        CallEndReason.declined => l10n.callDeclined,
        CallEndReason.noAnswer => l10n.callNoAnswer,
        CallEndReason.busy => l10n.callBusy,
        CallEndReason.unavailable => l10n.callUnavailable,
        CallEndReason.microphoneDenied => l10n.callMicrophoneNeeded,
        CallEndReason.connectionLost => l10n.callConnectionLost,
        CallEndReason.failed => l10n.callFailed,
        CallEndReason.answeredElsewhere => l10n.callAnsweredElsewhere,
        CallEndReason.hungUp || null => l10n.callEnded,
      },
      CallPhase.idle => '',
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: context.colors.textMuted,
        ),
      ),
    );
  }

  static String _duration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return duration.inHours > 0
        ? '${duration.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _IncomingActions extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingActions({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: Icons.call_end,
          label: context.l10n.callDecline,
          background: context.colors.danger,
          onPressed: onDecline,
        ),
        CallActionButton(
          icon: Icons.call,
          label: context.l10n.callAccept,
          background: context.colors.success,
          onPressed: onAccept,
        ),
      ],
    );
  }
}

class _LiveActions extends StatelessWidget {
  final CallState call;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onHangUp;

  const _LiveActions({
    required this.call,
    required this.onMute,
    required this.onSpeaker,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CallActionButton(
          icon: call.muted ? Icons.mic_off : Icons.mic_none,
          label: call.muted ? l10n.callUnmute : l10n.callMute,
          selected: call.muted,
          onPressed: onMute,
        ),
        CallActionButton(
          icon: Icons.call_end,
          label: l10n.callHangUp,
          background: context.colors.danger,
          onPressed: onHangUp,
        ),
        CallActionButton(
          icon: call.speakerOn ? Icons.volume_up : Icons.volume_down_outlined,
          label: l10n.callSpeaker,
          selected: call.speakerOn,
          onPressed: onSpeaker,
        ),
      ],
    );
  }
}
