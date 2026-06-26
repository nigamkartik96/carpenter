import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carpenter_app/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CarpenterHubApp());
    await tester.pump();

    expect(find.text('CarpenterHub'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
