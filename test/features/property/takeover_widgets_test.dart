import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/takeover_details_section.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/fields/property_select_field.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/takeover_terms_form.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_item_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_grid_section.dart';
import 'package:tilomnov/features/property/presentation/widgets/takeover_badge.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import '../../support/test_app.dart';
import 'takeover_fixture.dart';

Finder _field(String label) =>
    find.byWidgetPredicate((w) => w is PropertyTextField && w.label == label);
Finder _dropdown(String label) =>
    find.byWidgetPredicate((w) => w is PropertyDropdown && w.label == label);

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.descendant(
    of: _field(label),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _pick(WidgetTester tester, String label, String value) async {
  final field = find.descendant(
    of: _dropdown(label),
    matching: find.byType(PropertySelectField),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> _date(WidgetTester tester, String label) async {
  final field = find.descendant(
    of: _field(label),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'create a takeover through the form and publish the complete API payload',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = StubServer(
        (request) => request.method == 'GET'
            ? (200, '[]')
            : (
                201,
                jsonEncode({
                  ...request.data as Map,
                  'id': 'new-takeover',
                  'createdAt': '2026-11-08T00:00:00Z',
                }),
              ),
      );
      await pumpTestApp(
        tester,
        const AddPropertyPage(boundaryPoints: [], propertyArea: 100),
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'u1',
              role: 'user',
              createdAt: DateTime(2026),
              phone: '+85512345678',
            ),
          ),
          propertyRepositoryProvider.overrideWithValue(
            PropertyRepository(api.dio),
          ),
          publishingAllowanceProvider.overrideWith(
            (ref) async => PublishingAllowance(tier: PlanTier.free, used: 0),
          ),
        ],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AddPropertyPage)),
      );
      await _enter(tester, l10n.propertyTitleHeadline, 'Take over this plot');
      await _pick(
        tester,
        l10n.propertyListingSettings,
        l10n.listingTypeTakeover,
      );
      expect(find.byType(TakeoverTermsForm), findsOneWidget);
      expect(_field(l10n.propertyPrice), findsNothing);
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await _pick(
        tester,
        l10n.takeoverProviderType,
        l10n.takeoverProviderDeveloper,
      );
      await _enter(tester, l10n.takeoverProviderName, 'Example Developer');
      await _enter(tester, l10n.takeoverProjectName, 'Example Project');
      await _enter(tester, l10n.takeoverSellerAmount, '20000.25');
      await _enter(tester, l10n.takeoverBalance, '60000');
      await _date(tester, l10n.takeoverBalanceDate);
      await _enter(tester, l10n.takeoverPaymentAmount, '500.75');
      await _pick(tester, l10n.takeoverFrequency, l10n.takeoverMonthly);
      await _enter(tester, l10n.takeoverRemainingMonths, '120');
      await _date(tester, l10n.takeoverNextPayment);
      await _pick(tester, l10n.takeoverInterestType, l10n.takeoverInterestNone);
      await _pick(tester, l10n.takeoverTransferStatus, l10n.takeoverNotChecked);
      await _pick(tester, l10n.takeoverFeePayer, l10n.takeoverBuyer);
      await _enter(tester, l10n.takeoverArrears, '0');
      await _pick(tester, l10n.takeoverHasAdditional, l10n.propertyOptionNo);
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      final body =
          api.requests.singleWhere((r) => r.method == 'POST').body as Map;
      expect(body['listingType'], 'Takeover Payments');
      expect(body['status'], 'Active');
      expect(body['price'], 80000.25);
      expect(body['takeover'], containsPair('paymentAmount', 500.75));
      expect(body['takeover'], containsPair('hasAdditionalPayments', false));
      expect(body['discountValue'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing keeps terms and supports adding/removing larger payments',
    (tester) async {
      final emitted = <Map<String, dynamic>>[];
      await pumpTestApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: TakeoverTermsForm(
              initialTerms: takeoverFixture,
              onChanged: (terms) => emitted.add(terms.toJson()),
            ),
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TakeoverTermsForm)),
      );
      await _enter(tester, l10n.takeoverSellerAmount, '15000.50');
      expect(emitted.last['sellerAmount'], 15000.5);
      expect(emitted.last['annualInterestRate'], 6.75);
      expect(emitted.last['additionalPayments'], hasLength(1));
      final add = find.text(l10n.takeoverAddPayment);
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
      expect(emitted.last['additionalPayments'], hasLength(2));
      final remove = find.text(l10n.takeoverRemovePayment).last;
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(emitted.last['additionalPayments'], hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'km']) {
    testWidgets('takeover cards fit narrow layouts in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final listing = takeoverListingFixture();
      for (final card in <Widget>[
        SizedBox(
          width: 320,
          height: 280,
          child: PropertyItemCard(property: listing, onTap: () {}),
        ),
        SizedBox(
          width: 154,
          height: 260,
          child: SavedPropertyCard(
            property: listing,
            onTap: () {},
            onViewOnMap: () {},
          ),
        ),
        PropertyCard(
          property: listing,
          onOptionsTapped: () {},
          onStatusTapped: () {},
          onInsightsTapped: () {},
        ),
        PropertyShareCard(property: listing),
        PropertyGridSection(
          title: 'Similar',
          properties: [listing],
          onPropertyTapped: (_, _) {},
        ),
      ]) {
        await pumpTestApp(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Align(alignment: Alignment.topLeft, child: card),
            ),
          ),
          savedSettings: {'settings.language': language},
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${card.runtimeType} in $language',
        );
      }
    });

    testWidgets(
      'buyer breakdown fits a narrow screen in $language and preserves cents/rates',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpTestApp(
          tester,
          const Scaffold(
            body: SingleChildScrollView(
              child: TakeoverDetailsSection(terms: takeoverFixture),
            ),
          ),
          savedSettings: {'settings.language': language},
        );
        final context = tester.element(find.byType(TakeoverDetailsSection));
        expect(Localizations.localeOf(context).languageCode, language);
        expect(find.text(r'$ 20,000.25'), findsOneWidget);
        expect(find.text(r'$ 500.75'), findsOneWidget);
        expect(find.text('6.75%'), findsOneWidget);
        expect(find.textContaining(r'$ 10,000'), findsOneWidget);
        expect(find.byType(TakeoverBadge), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('map card identifies takeover pricing and has a purple badge', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: SizedBox(
          width: 390,
          height: 280,
          child: PropertyItemCard(
            property: takeoverListingFixture(),
            onTap: () {},
          ),
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PropertyItemCard)),
    );
    expect(find.byType(TakeoverBadge), findsOneWidget);
    expect(
      find.text(PropertyFormat.cardPrice(l10n, takeoverListingFixture())),
      findsOneWidget,
    );
    expect(
      PropertyFormat.takeoverSummary(l10n, takeoverListingFixture()),
      contains(r'$ 20,000.25'),
    );
    expect(tester.takeException(), isNull);
  });
}
