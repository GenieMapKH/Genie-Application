// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/payment_success.dart';
import 'package:tilomnov/features/payment/presentation/screens/one_time_payment_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/publishing_plan_selector.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

import 'add_property_page.dart';
import 'add_property_page_form_binding.dart';
import 'add_property_page_logic.dart';

/// Publishing a new listing that does not fit in the user's plan: paid
/// once, or after subscribing to a plan with room.
extension AddPropertyPaidPublish on AddPropertyPageState {
  /// Whether the user's plan is full, so this listing needs a publishing plan.
  bool get needsPublishingPlan =>
      ref.read(publishingAllowanceProvider).valueOrNull?.hasRoom == false;

  /// Publishes the listing the way the user chose; asks them to choose first.
  Future<void> publishBeyondPlan({
    required Future<void> Function() publishInPlan,
  }) async {
    switch (selectedPublishingPlan) {
      case null:
        setState(() => publishingPlanMissing = true);
        AppPopup.showInfo(context, context.l10n.publishPlanChooseFirst);
        final section = publishingPlanKey.currentContext;
        if (section != null) {
          await Scrollable.ensureVisible(
            section,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      case PublishingPlan.subscription:
        await _subscribeThenPublish(publishInPlan);
      case PublishingPlan.oneTime:
        await _payOnceThenPublish();
    }
  }

  /// Opens the plans; once subscribed, the listing fits and goes out free.
  Future<void> _subscribeThenPublish(
    Future<void> Function() publishInPlan,
  ) async {
    final subscribed = await context.pushPage<bool>(
      const SubscriptionPlansPage(),
    );
    if (subscribed != true || !mounted) return;
    ref.invalidate(publishingAllowanceProvider);
    // A one-time payment tried before may have saved it as a draft already.
    final draft = unpaidDraft;
    if (draft == null) {
      await publishInPlan();
    } else {
      await _publishSavedDraft(draft);
    }
  }

  Future<void> _publishSavedDraft(PropertyModel draft) async {
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .publish(draft.id);
      ownListingsChangedFrom(ref);
      if (mounted) showSuccessDialog(property);
    } catch (e, stackTrace) {
      AppLogger.error('Publishing the saved draft failed', e, stackTrace);
      if (mounted) {
        showFailure(
          context,
          error: e,
          fallback: context.l10n.propertySaveFailed,
        );
      }
    }
  }

  Future<void> _payOnceThenPublish() async {
    final addPage = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    PropertyModel? awaitingConfirmation;
    await context.pushPage<bool>(
      OneTimePaymentPage(
        listingRows: _listingRows(),
        fee: PlanCatalog.oneTimePublishFeeUsd,
        onPublish: (method) async {
          final (property, outcome) = await _publishPaidOnce(method);
          if (property == null || outcome == null || !mounted) return false;
          if (!outcome.isPaid) {
            // Told already; it goes live once ABA confirms.
            awaitingConfirmation = property;
            return true;
          }
          await showPaymentSuccess(
            context,
            ref,
            receipt: PaymentReceipt(
              transactionId: outcome.transactionId ?? '',
              amountUsd: PlanCatalog.oneTimePublishFeeUsd,
              item: context.l10n.paymentItemOneTimePublish,
              method: method,
              paidAt: DateTime.now(),
              email: ref.read(userProfileProvider).valueOrNull?.email,
            ),
            // Back to where the listing was started, with it.
            onDone: () => navigator
              ..popUntil((route) => route == addPage)
              ..pop(property),
          );
          return false;
        },
      ),
    );
    final pending = awaitingConfirmation;
    if (pending != null && mounted) navigator.pop(pending);
  }

  /// Saves the listing privately, pays its one-time fee by [method] and
  /// answers it once published (or waiting for ABA), with how the payment
  /// ended; no listing when it is not.
  Future<(PropertyModel?, PaymentOutcome?)> _publishPaidOnce(
    PaymentMethod method,
  ) async {
    final checkout = ref.read(paymentCheckoutServiceProvider);
    try {
      // Kept private until paid, so nothing typed is lost if paying fails,
      // and a second try pays for the same listing.
      final draft = unpaidDraft ??= await ref
          .read(addPropertyControllerProvider.notifier)
          .submitProperty(
            input: collectFormInput(),
            boundaryPoints: widget.boundaryPoints,
            selectedPhotos: selectedPhotos,
            status: 'Draft',
          );
      if (draft == null) return (null, null);
      final outcome = await checkout.payForListing(draft.id, method);
      if (!mounted) return (null, outcome);
      switch (outcome.result) {
        case PaymentResult.paid:
          unpaidDraft = null;
          // A simulated payment never reaches the server, so publish the
          // listing as the server would have once paid.
          final live = checkout.isSimulation
              ? await ref.read(propertyRepositoryProvider).publish(draft.id)
              : draft;
          ownListingsChangedFrom(ref);
          return (live, outcome);
        case PaymentResult.awaitingConfirmation:
          showUnfinishedPayment(context, outcome.result);
          return (draft, outcome);
        case PaymentResult.failed || PaymentResult.notOpened:
          showUnfinishedPayment(context, outcome.result);
          return (null, outcome);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Paid publish failed', e, stackTrace);
      if (mounted) showPaymentError(context, e);
      return (null, null);
    }
  }

  /// What the listing is, for the checkout.
  List<(String, String)> _listingRows() {
    final l10n = context.l10n;
    return [
      (l10n.paymentProperty, propertyValueLabel(l10n, selectedPropertyType)),
      (l10n.paymentCategory, propertyValueLabel(l10n, selectedListingSetting)),
      (l10n.paymentPrice, PropertyFormat.price(effectivePrice)),
    ];
  }
}
