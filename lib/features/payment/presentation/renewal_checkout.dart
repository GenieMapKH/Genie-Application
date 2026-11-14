import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/payment_success.dart';
import 'package:tilomnov/features/payment/presentation/screens/one_time_payment_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Both renewal checkouts use the app's existing billing screens and payment flow.
Future<bool?> showRenewalCheckout(BuildContext context, Widget checkout) =>
    showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 540),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: checkout,
      ),
    );

Future<bool> renewProperty(
  BuildContext context,
  WidgetRef ref,
  PropertyModel property,
) async {
  final paid = await showRenewalCheckout(
    context,
    OneTimePaymentPage(
      isRenewal: true,
      onChooseSubscription: () async {
        try {
          final subscribed = await context.pushPage<bool>(
            const SubscriptionPlansPage(),
          );
          if (subscribed != true || !context.mounted) return false;
          await ref.read(propertyRepositoryProvider).publish(property.id);
          ownListingsChangedFrom(ref);
          ref.invalidate(propertyDetailProvider(property.id));
          return true;
        } catch (error) {
          if (context.mounted) showPaymentError(context, error);
          return false;
        }
      },
      listingRows: [(context.l10n.paymentProperty, property.title)],
      fee: PlanCatalog.oneTimePublishFeeUsd,
      onPublish: (method) async {
        try {
          final outcome = await ref
              .read(paymentCheckoutServiceProvider)
              .payForListing(property.id, method);
          if (!context.mounted) return false;
          if (!outcome.isPaid) {
            showUnfinishedPayment(
              context,
              outcome.result,
              transactionId: outcome.transactionId,
            );
            return false;
          }
          ownListingsChangedFrom(ref);
          ref.invalidate(propertyDetailProvider(property.id));
          ref.invalidate(publishingAllowanceProvider);
          await showPaymentSuccess(
            context,
            receipt: PaymentReceipt(
              transactionId: outcome.transactionId ?? '',
              isSimulation: outcome.isSimulation,
              amountUsd: outcome.amountUsd ?? PlanCatalog.oneTimePublishFeeUsd,
              item: context.l10n.paymentItemOneTimePublish,
              method: method,
              paidAt: outcome.paidAt ?? DateTime.now(),
              email: ref.read(userProfileProvider).valueOrNull?.email,
            ),
            onDone: () => Navigator.of(context, rootNavigator: true).pop(),
          );
          return true;
        } catch (error) {
          if (context.mounted) showPaymentError(context, error);
          return false;
        }
      },
    ),
  );
  return paid == true;
}
