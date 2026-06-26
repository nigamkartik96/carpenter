import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_console/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminConsoleApp());
    await tester.pump();

    expect(find.text('CarpenterHub admin'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
