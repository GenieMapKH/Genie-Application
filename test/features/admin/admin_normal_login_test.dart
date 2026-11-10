import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/main_map_view.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/main_map_controls.dart';
import 'package:tilomnov/features/home/presentation/widgets/search/home_search_panel.dart';
import 'package:flutter/services.dart';
// The map plugin is replaced at its platform boundary for this widget test.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/app/router/app_router.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/admin/data/admin_dashboard_repository.dart';
import 'package:tilomnov/features/admin/data/admin_service_health.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_page.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_provider.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/features/auth/presentation/screens/login_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/admin_email_page.dart';
import 'package:tilomnov/features/auth/presentation/view_models/login_controller.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/home/presentation/screens/main_layout.dart';
import 'package:tilomnov/features/profile/presentation/screens/user_profile_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/listing_refresh_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';
import '../../support/test_app.dart';

class _TestMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

void main() {
  testWidgets(
    'email-verified admin session opens the dashboard, and signed-out callers return to login',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final originalMaps = GoogleMapsFlutterPlatform.instance;
      GoogleMapsFlutterPlatform.instance = _TestMaps();
      addTearDown(() => GoogleMapsFlutterPlatform.instance = originalMaps);
      const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        locationChannel,
        (_) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          locationChannel,
          null,
        ),
      );
      final data = AdminDashboardData.fromJson({
        'generatedAt': '2026-11-09T10:00:00Z',
        'users': {'total': 2, 'active': 2, 'newLast7Days': 1},
        'openReports': 0,
        'listings': {
          'total': 1,
          'active': 1,
          'newLast7Days': 1,
          'leadsLast7Days': 0,
        },
        'payments': {
          'activeSubscriptions': 0,
          'pendingTransactions': 0,
          'successfulTransactions7d': 0,
          'volumeUsd7d': 0,
          'simulated': true,
          'subscriptionsByTier': <String, dynamic>{},
        },
      });
      final claims = base64Url
          .encode(
            utf8.encode(
              jsonEncode({'sub': 'owner', 'role': 'admin', 'adminMfa': true}),
            ),
          )
          .replaceAll('=', '');
      final server = StubServer(
        (request) => switch (request.path) {
          '/auth/login' => (
            200,
            jsonEncode({'status': 'admin_email_required'}),
          ),
          '/auth/admin-login/complete' => (
            200,
            jsonEncode({
              'accessToken': 'header.$claims.signature',
              'refreshToken': 'refresh',
            }),
          ),
          _ => (503, '{}'),
        },
      );
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsStorage(
        await SharedPreferences.getInstance(),
      );
      final container = ProviderContainer(
        overrides: [
          appSettingsStorageProvider.overrideWithValue(settings),
          apiClientProvider.overrideWithValue(server.dio),
          listingRefreshProvider.overrideWith((_) => const Stream<int>.empty()),
          adminDashboardProvider.overrideWith((_) async => data),
          adminSystemHealthProvider.overrideWith(
            (_) async => AdminSystemHealth.fromJson({
              'checkedAt': '2026-11-09T10:00:00Z',
              'services': <Map<String, dynamic>>[],
            }),
          ),
        ],
      );
      final router = container.read(routerProvider);
      addTearDown(() {
        router.dispose();
        container.dispose();
      });
      router.go('/login');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      final success = await tester.runAsync(
        () => container
            .read(loginControllerProvider.notifier)
            .login('owner@example.com', 'password'),
      );
      expect(success, isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(AdminEmailPage), findsOneWidget);
      expect(await AuthStorage.getAccessToken(), isNull);
      expect(find.textContaining('Open Gmail'), findsOneWidget);
      router.go('/admin-login?token=${'a' * 43}');
      await tester.pumpAndSettle();
      expect(find.byType(MainLayout), findsOneWidget);
      final mapState = tester.state(find.byType(MainMapView));
      expect(find.text('Feed'), findsNothing);
      expect(tester.getSize(find.byType(MainMapView)).height, greaterThan(400));
      for (final label in [
        'Explore',
        'Services',
        'Account',
        'Activity',
        'Financial',
        'Profile',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardPage), findsOneWidget);
      for (final label in [
        'Services',
        'Account',
        'Activity',
        'Financial',
        'Profile',
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        final page = find.byType(
          label == 'Profile' ? UserProfilePage : AdminDashboardPage,
        );
        expect(
          tester.getSize(page).height,
          greaterThan(400),
          reason: '$label must fill the page above navigation',
        );
        expect(
          tester.getSize(page).width,
          tester.getSize(find.byType(MainLayout)).width,
        );
        expect(
          find.descendant(of: page, matching: find.byType(Text)).hitTestable(),
          findsWidgets,
        );
      }
      expect(tester.state(find.byType(MainMapView)), same(mapState));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MainMapView), findsOneWidget);
      expect(find.byType(MainMapControls), findsOneWidget);
      expect(find.byType(HomeSearchPanel), findsNWidgets(2));
      await AuthStorage.clearTokens();
      router.go('/admin/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    },
  );

  testWidgets(
    'an invalid email link leaves the app signed out and offers login',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final server = StubServer.always(
        401,
        '{"message":"Invalid or expired sign-in link"}',
      );
      await pumpTestApp(
        tester,
        const AdminEmailPage(token: 'expired'),
        overrides: [apiClientProvider.overrideWithValue(server.dio)],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be verified'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);
      expect(await AuthStorage.getAccessToken(), isNull);
    },
  );
}
