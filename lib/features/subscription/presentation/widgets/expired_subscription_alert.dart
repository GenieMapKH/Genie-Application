import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/payment/presentation/renewal_checkout.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/subscription/domain/account_subscription.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';

/// Checks again on resume; each expired period prompts once per app session.
class ExpiredSubscriptionAlert extends ConsumerStatefulWidget {
  const ExpiredSubscriptionAlert({super.key});
  @override
  ConsumerState<ExpiredSubscriptionAlert> createState() =>
      _ExpiredSubscriptionAlertState();
}

class _ExpiredSubscriptionAlertState
    extends ConsumerState<ExpiredSubscriptionAlert>
    with WidgetsBindingObserver {
  final _shown = <String>{};
  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(expiredSubscriptionProvider);
      ref.invalidate(accountSubscriptionProvider);
      ownListingsChangedFrom(ref);
    }
  }

  Future<void> _show(AccountSubscription expired) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    final key = '${user?.id}:${expired.expiresAt.toIso8601String()}';
    if (!mounted ||
        user == null ||
        user.role == 'admin' ||
        _open ||
        _shown.contains(key) ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _shown.add(key);
    _open = true;
    try {
      await showRenewalCheckout(
        context,
        UpgradeSubscriptionPage(
          plan: PlanCatalog.of(expired.tier),
          isRenewal: true,
        ),
      );
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final expired = ref.watch(expiredSubscriptionProvider).valueOrNull;
    if (expired != null && profile != null && profile.role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _show(expired);
      });
    }
    return const SizedBox.shrink();
  }
}
