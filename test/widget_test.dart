// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:password_manager/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const PasswordManagerApp());
    await tester.pump();

    // Should land on either the Login screen or Home screen depending
    // on whether a session is already active, both of which render a
    // Scaffold — this just confirms the app didn't crash on startup.
    expect(find.byType(Scaffold), findsWidgets);

  });
}
