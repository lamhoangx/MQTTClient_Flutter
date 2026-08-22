// Smoke test: the app builds and shows the broker page with its
// navigation destinations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mqtt_client_example/main.dart';

void main() {
  testWidgets('Broker page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // App bar title and connection state icon are shown.
    expect(find.text('MQTT'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsWidgets);

    // Navigation destinations are shown.
    expect(find.text('Broker'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);

    // Connect button is visible and not connected yet.
    expect(find.text('Connect'), findsOneWidget);
  });
}
