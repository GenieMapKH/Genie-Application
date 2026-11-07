import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/payment/application/simulated_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/one_time_payment_page.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';

import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

import '../../support/test_app.dart';

const _square = [
  LatLng(11.5500, 104.9200),
  LatLng(11.5500, 104.92092),
  LatLng(11.5509, 104.92092),
  LatLng(11.5509, 104.9200),
];

/// Records what each new listing is created with.
class _Server extends PropertyRepository {
  final created = <Map<String, dynamic>>[];

  _Server() : super(Dio());

  @override
  Future<PropertyModel> create(Map<String, dynamic> data) async {
    created.add(data);
    return _listing(data['status'] as String);
  }

  static PropertyModel _listing(String status) => PropertyModel.fromJson({
    'id': 'p-new',
    'title': 'Plot',
    'price': '0',
    'propertyType': 'Land',
    'status': status,
    'createdAt': '2026-11-04T00:00:00.000Z',
  });

  final published = <String>[];
  final fetched = <String>[];

  @override
  Future<PropertyModel> fetchPropertyDetail(String id) async {
    fetched.add(id);
    return _listing('Active');
  }

  @override
  Future<PropertyModel> publish(String id) async {
    published.add(id);
    return _listing('Active');
  }

  @override
  Future<PropertyModel> updateBoundary(
    String id,
    List<Map<String, double>> boundaryPoints,
  ) async => _listing(created.last['status'] as String);
}

Future<void> _openAddPage(
  WidgetTester tester,
  _Server server, {
  required int used,
}) async {
  // A phone screen, so the checkout's method sits above its button.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () => context.pushPage(
          const AddPropertyPage(boundaryPoints: _square, propertyArea: 10000),
        ),
        child: const Text('open'),
      ),
    ),
    overrides: [
      paymentCheckoutServiceProvider.overrideWithValue(
        SimulatedPaymentCheckoutService(
          repository: PaymentRepository(
            StubServer.always(
              201,
              '{"transactionId":"tx-mock","status":"Success","isSimulation":true}',
            ).dio,
          ),
        ),
      ),
      receiptMailerProvider.overrideWithValue(MockReceiptMailer()),
      propertyRepositoryProvider.overrideWithValue(server),
      publishingAllowanceProvider.overrideWith(
        (ref) async => PublishingAllowance(tier: PlanTier.free, used: used),
      ),
    ],
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  final form = tester.state<AddPropertyPageState>(find.byType(AddPropertyPage));
  form.titleController.text = 'Plot by the river';
  form.priceController.text = '350000';
}

Future<void> _pressPublish(WidgetTester tester) async {
  await tester.tap(find.text('Publish'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the first listing needs no publishing plan', (tester) async {
    await _openAddPage(tester, _Server(), used: 0);
    expect(
      find.text('Choose Publishing Plan *', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('past the plan, Publish waits for a publishing plan', (
    tester,
  ) async {
    final server = _Server();
    await _openAddPage(tester, server, used: 1);

    await tester.scrollUntilVisible(
      find.text('One-Time Publish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Choose Publishing Plan *', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Subscription Plan'), findsOneWidget);

    await _pressPublish(tester);
    expect(
      find.text(
        'Please choose a publishing plan or a one-time payment to publish this property.',
      ),
      findsOneWidget,
    );
    expect(server.created, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('one-time publish goes through its checkout', (tester) async {
    final server = _Server();
    await _openAddPage(tester, server, used: 1);

    await tester.scrollUntilVisible(
      find.text('One-Time Publish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('One-Time Publish'));
    await tester.pumpAndSettle();
    await _pressPublish(tester);
    await tester.pumpAndSettle();

    expect(find.byType(OneTimePaymentPage), findsOneWidget);
    expect(find.text('Land'), findsOneWidget);
    expect(find.text(r'$ 350,000'), findsOneWidget);
    expect(find.text(r'$1.00'), findsNWidgets(2));

    // No method picked yet: nothing happens.
    await tester.tap(find.text('Publish Property'));
    await tester.pumpAndSettle();
    expect(server.created, isEmpty);

    await tester.tap(find.text('ABA KHQR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish Property'));
    await tester.pumpAndSettle();

    // Saved privately, paid (simulated), then published.
    expect(server.created.single['status'], 'Draft');
    expect(server.published, isEmpty);
    expect(server.fetched, ['p-new']);
    expect(find.byType(PaymentSuccessPage), findsOneWidget);
    expect(find.text('1 USD'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSuccessPage), findsNothing);
    expect(find.byType(OneTimePaymentPage), findsNothing);
    expect(find.byType(AddPropertyPage), findsNothing);
  });
}
