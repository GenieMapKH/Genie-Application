import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:genie/app/navigation/call_navigation.dart';
import 'package:genie/app/router/app_router.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/visible_conversation.dart';
import 'package:genie/features/notifications/application/push_notifications_controller.dart';
import 'package:genie/features/notifications/models/push_message.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:genie/features/security/presentation/screens/devices_page.dart';
import 'package:genie/shared/widgets/layout/app_page_scaffold.dart';

/// Opens what a tapped notification is about. It lives in `app/` because it
/// leads into several features: chat, security, listings.
PushOpener pushOpener(Ref ref) {
  return (message) async {
    final context = await _signedInContext(ref.read(routerProvider));
    if (context == null || !context.mounted) return;

    switch (message) {
      case ChatMessagePush(:final senderId, :final senderName):
        // Already there: nothing to open.
        if (ref.read(visibleConversationProvider).participantId == senderId) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatConversationPage(
              participantId: senderId,
              participantName: senderName,
            ),
          ),
        );
      case SignInAlertPush():
        await context.pushPage(const DevicesPage());
      case PromotionPush(:final propertyId, :final url):
        await _openPromotion(ref, context, propertyId: propertyId, url: url);
      case ListingAlertPush(:final propertyId):
        await _openPromotion(ref, context, propertyId: propertyId, url: null);
      case IncomingCallPush():
        await openCallFromPush(ref, message);
      case CallEndedPush() || UnknownPush():
        // A missed call or anything else just opens the app.
        break;
    }
  };
}

/// Hides a notification about the conversation already on screen.
ForegroundPushFilter foregroundPushFilter(Ref ref) {
  return (message) => switch (message) {
    ChatMessagePush(:final senderId) =>
      ref.read(visibleConversationProvider).participantId != senderId,
    _ => true,
  };
}

Future<void> _openPromotion(
  Ref ref,
  BuildContext context, {
  required String? propertyId,
  required Uri? url,
}) async {
  if (propertyId != null) {
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .fetchPropertyDetail(propertyId);
      if (context.mounted) {
        await Navigator.of(context).push(PropertyDetailSheet.route(property));
      }
      return;
    } catch (e, stackTrace) {
      // Sold or taken down since: the web page, if any, is next best.
      AppLogger.error('Promoted listing could not be opened', e, stackTrace);
    }
  }
  if (url != null) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// The app's navigator once someone is signed in and the home screen is up;
/// null for a guest (a notification never reaches one, but a stale one may).
Future<BuildContext?> _signedInContext(GoRouter router) async {
  final token = await AuthStorage.getAccessToken();
  if (token == null || token.isEmpty) return null;

  // A cold start from a notification: the router may still be on its way.
  for (var attempt = 0; attempt < 50; attempt++) {
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      if (router.routerDelegate.currentConfiguration.uri.path != '/home') {
        router.go('/home');
      }
      await WidgetsBinding.instance.endOfFrame;
      return router.routerDelegate.navigatorKey.currentContext;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}
