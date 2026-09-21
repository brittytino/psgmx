import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/ui/widgets/companion_page_header.dart';

void main() {
  testWidgets('home header fits a 320 pixel phone with batch and bell',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CompanionPageHeader(
                eyebrow: 'Good morning 👋',
                title: 'Alexandria',
                subtitle: 'Let\'s build one strong step today.',
                actions: [
                  Chip(label: Text('26MX')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Good morning 👋'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
