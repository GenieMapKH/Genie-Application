import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/call/providers/call_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Stays above navigation so a minimized call is always reachable.
class MiniCallBar extends ConsumerWidget {
  const MiniCallBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    if (!call.isLive || !ref.watch(callMinimizedProvider)) {
      return const SizedBox.shrink();
    }
    return Overlay.wrap(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - 24,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () =>
                            ref.read(callMinimizedProvider.notifier).state =
                                false,
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: Text(
                          call.peerName ?? context.l10n.callReturn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.callHangUp,
                      icon: const Icon(Icons.call_end, color: Colors.redAccent),
                      onPressed: ref
                          .read(callControllerProvider.notifier)
                          .hangUp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
