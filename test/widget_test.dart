import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planty_flutter_starter/main.dart';
import 'package:planty_flutter_starter/db/app_db.dart'; // <-- DB importieren

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // DB-Instanz für den Test erzeugen
    final db = AppDb();

    // App starten mit DB
    await tester.pumpWidget(PlantyApp());

    // Beispiel-Test (nur Dummy, kannst du anpassen)
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
