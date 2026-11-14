import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

class SubscriptionStatus extends ConsumerStatefulWidget {
  final bool onDark;

  const SubscriptionStatus({super.key, this.onDark = false});

  @override
  ConsumerState<SubscriptionStatus> createState() => _SubscriptionStatusState();
}

class _SubscriptionStatusState extends ConsumerState<SubscriptionStatus> {
  bool _cancelling = false;

  Future<void> _cancel(String expiresAt) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context,
      builder: (_) => AppDialog(
        icon: LucideIcons.calendarCheck,
        title: l10n.planCancelTitle,
        message: l10n.planCancelExplanation(expiresAt),
        primaryLabel: l10n.planCancelAction,
        secondaryLabel: l10n.commonCancel,
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(paymentRepositoryProvider).cancelSubscription();
      ref.invalidate(accountSubscriptionProvider);
    } catch (error) {
      if (mounted) {
        showFailure(context, error: error, fallback: l10n.planCancelFailed);
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountSubscriptionProvider);
    final ink = widget.onDark ? Colors.white : null;
    if (state.hasError) {
      return TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: ink),
        onPressed: () => ref.invalidate(accountSubscriptionProvider),
        icon: const Icon(LucideIcons.refreshCw),
        label: Text(context.l10n.planStatusRetry),
      );
    }
    final subscription = state.valueOrNull;
    if (subscription == null) return const SizedBox.shrink();
    final expiresAt = DateFormat.yMMMd(
      context.l10n.localeName,
    ).add_jm().format(subscription.expiresAt.toLocal());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subscription.cancelAtPeriodEnd
              ? context.l10n.planCancelledUntil(expiresAt)
              : context.l10n.planActiveUntil(expiresAt),
          style: TextStyle(color: ink),
        ),
        if (!subscription.cancelAtPeriodEnd) ...[
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: context.colors.dangerSoft,
              foregroundColor: context.colors.onDangerSoft,
            ),
            onPressed: _cancelling ? null : () => _cancel(expiresAt),
            child: _cancelling
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.onDangerSoft,
                    ),
                  )
                : Text(context.l10n.planCancelAction),
          ),
        ],
      ],
    );
  }
}
