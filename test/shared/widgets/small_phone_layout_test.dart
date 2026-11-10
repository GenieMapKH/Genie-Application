import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/profile/presentation/screens/user_profile_page.dart';
import 'package:tilomnov/features/profile/presentation/screens/personal_info_page.dart';
import 'package:tilomnov/features/security/presentation/screens/security_page.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_grid_section.dart';
import 'package:tilomnov/features/auth/presentation/screens/welcome_page.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/drawing_controls_panel.dart';
import 'package:tilomnov/features/payment/presentation/screens/one_time_payment_page.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_submit_bar.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_type_selector.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';
import 'package:tilomnov/shared/widgets/buttons/app_button.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

import '../../support/test_app.dart';

void main() {
  for (final width in [280.0, 320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final language in ['en', 'km']) {
        final scenario = '${width.toInt()}px $language text $scale';
        Future<void> pump(WidgetTester tester, Widget child) async {
          tester.view.physicalSize = Size(width, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpTestApp(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child,
              ),
            ),
            savedSettings: {'settings.language': language},
            overrides: [
              signedInOverride(signedIn: false),
              userProfileProvider.overrideWith(
                (_) async => UserProfile(
                  id: 'layout-user',
                  role: 'user',
                  name: 'A long profile display name',
                  username: 'long_profile_username',
                  email: 'long-address@example.com',
                  createdAt: DateTime(2026),
                ),
              ),
              accountSubscriptionProvider.overrideWith((_) async => null),
            ],
          );
          await tester.pumpAndSettle();
        }

        testWidgets('drawing actions stay separate and tappable: $scenario', (
          tester,
        ) async {
          final taps = <String>[];
          await pump(
            tester,
            Scaffold(
              body: DrawingControlsPanel(
                isEditingPolygon: false,
                onRevertPressed: () => taps.add('undo'),
                onDeletePressed: () => taps.add('delete'),
                onCancelPressed: () => taps.add('cancel'),
                onSavePressed: () => taps.add('save'),
                onAddPinPressed: () => taps.add('pin'),
              ),
            ),
          );
          final buttons = find.byType(TactileButton);
          expect(buttons, findsNWidgets(5));
          final rects = [
            for (final e in buttons.evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ];
          final covered = DrawingControlsPanel.coveredBottomOf(
            tester.element(find.byType(DrawingControlsPanel)),
          );
          for (var i = 0; i < rects.length; i++) {
            expect(rects[i].left, greaterThanOrEqualTo(0));
            expect(rects[i].right, lessThanOrEqualTo(width));
            expect(rects[i].bottom, lessThanOrEqualTo(568));
            expect(rects[i].top, greaterThanOrEqualTo(568 - covered - 0.01));
            for (var j = i + 1; j < rects.length; j++) {
              expect(rects[i].overlaps(rects[j]), isFalse);
            }
            await tester.tap(buttons.at(i));
          }
          expect(taps, ['undo', 'delete', 'cancel', 'save', 'pin']);
          expect(tester.takeException(), isNull);
        });

        testWidgets(
          'all property tiles are equal within parent width: $scenario',
          (tester) async {
            String? picked;
            await pump(
              tester,
              Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: PropertyTypeSelector(
                      selectedPropertyType: 'House',
                      onChanged: (value) => picked = value,
                    ),
                  ),
                ),
              ),
            );
            final tiles = find.byType(AnimatedContainer);
            expect(tiles, findsNWidgets(7));
            final first = tester.getSize(tiles.first);
            for (final e in tiles.evaluate()) {
              final rect = tester.getRect(find.byWidget(e.widget));
              expect(rect.width, closeTo(first.width, 0.01));
              expect(rect.height, closeTo(first.height, 0.01));
              expect(rect.left, greaterThanOrEqualTo(32));
              expect(rect.right, lessThanOrEqualTo(width - 32 + 0.01));
            }
            await tester.ensureVisible(tiles.at(5));
            await tester.tap(tiles.at(5));
            expect(picked, 'Business for Sale');
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets('shared form actions and plan cards fit: $scenario', (
          tester,
        ) async {
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          await pump(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppButton.primary(
                        text: 'Continue with this business subscription',
                        icon: const Icon(Icons.check),
                        onPressed: () {},
                      ),
                      PropertyTextField(
                        label: 'Long property information',
                        infoText: 'Optional details about this property',
                        controller: controller,
                        hintText: 'Details',
                      ),
                      AddPropertySubmitBar(
                        children: [
                          AddPropertySubmitButton(
                            label: 'Archive property',
                            icon: Icons.archive,
                            onPressed: () {},
                          ),
                          AddPropertySubmitButton(
                            label: 'Publish property',
                            icon: Icons.upload,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      for (final plan in PlanCatalog.plans)
                        PlanCard(plan: plan, onUpgrade: () {}),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });

        testWidgets('welcome and payment pages fit short phones: $scenario', (
          tester,
        ) async {
          await pump(tester, const WelcomePage(splashDelay: Duration.zero));
          expect(tester.takeException(), isNull);
          await pump(
            tester,
            OneTimePaymentPage(
              listingRows: const [
                ('Property', 'Business for Sale with a long listing title'),
              ],
              fee: 1,
              onPublish: (_) async => true,
            ),
          );
        });

        testWidgets('account, security and plans fit: $scenario', (
          tester,
        ) async {
          for (final page in const [
            UserProfilePage(),
            PersonalInfoPage(),
            SecurityPage(),
            SubscriptionPlansPage(),
          ]) {
            await pump(tester, page);
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType}',
            );
            final scroll = find.byType(Scrollable).first;
            await tester.drag(scroll, const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType} after scroll',
            );
          }
        });

        testWidgets('add property form fits: $scenario', (tester) async {
          await pump(
            tester,
            const AddPropertyPage(boundaryPoints: [], propertyArea: 0),
          );
          expect(tester.takeException(), isNull);
          final scroll = find.byType(SingleChildScrollView).first;
          for (var step = 0; step < 6; step++) {
            await tester.drag(scroll, const Offset(0, -400));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });

        testWidgets('listing grid remains readable: $scenario', (tester) async {
          await pump(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PropertyGridSection(
                    title: 'Similar properties',
                    properties: [
                      for (var i = 0; i < 3; i++)
                        PropertyModel(
                          id: 'layout-$i',
                          title: 'Business for Sale with a long listing title',
                          price: '123456789',
                          propertyType: 'House',
                          status: 'Active',
                          ownerName: 'A long property owner display name',
                          createdAt: DateTime(2026),
                        ),
                    ],
                    onPropertyTapped: (_, _) {},
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
