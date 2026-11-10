import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/data/receipt_saver.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';

import '../../support/test_app.dart';

class _Saver implements ReceiptSaver {
  final saved = <(String, Uint8List)>[];

  @override
  Future<bool> saveToPhotos(Uint8List png, {required String name}) async {
    saved.add((name, png));
    return true;
  }
}

final _receipt = PaymentReceipt(
  transactionId: 'GP0001245',
  amountUsd: 1,
  item: 'One-time listing publish',
  method: PaymentMethod.abaKhqr,
  paidAt: DateTime(2026, 11, 4, 9, 30),
  email: 'hengheng168@gmail.com',
);

void main() {
  testWidgets('shows the payment like the receipt screen', (tester) async {
    await pumpTestApp(
      tester,
      PaymentSuccessPage(receipt: _receipt, onDone: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Success'), findsOneWidget);
    expect(find.text('1 USD'), findsOneWidget);
    expect(find.text('Transaction ID  #GP0001245'), findsOneWidget);
    expect(
      find.text(
        'Order confirmation email:\n'
        'hengheng168@gmail.com',
      ),
      findsOneWidget,
    );
    expect(find.text('Download Receipt'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets('Download Receipt keeps the receipt picture', (tester) async {
    final saver = _Saver();
    await pumpTestApp(
      tester,
      PaymentSuccessPage(receipt: _receipt, onDone: () {}, saver: saver),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Download Receipt'));
      await tester.pump();
      for (var i = 0; i < 20 && saver.saved.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    final (name, png) = saver.saved.single;
    expect(name, 'tilomnov-receipt-GP0001245');
    // A PNG's signature.
    expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Back to Home finishes the payment', (tester) async {
    var done = 0;
    await pumpTestApp(
      tester,
      PaymentSuccessPage(receipt: _receipt, onDone: () => done++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Home'));
    expect(done, 1);
  });
}
