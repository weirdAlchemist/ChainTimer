import 'package:chain_timer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows empty state, then creates and lists a chain',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ChainTimerApp());
    await tester.pumpAndSettle();

    // Empty state visible.
    expect(find.text('No chains yet'), findsOneWidget);
    expect(find.text('New chain'), findsOneWidget);

    // Open the editor.
    await tester.tap(find.text('New chain'));
    await tester.pumpAndSettle();
    expect(find.text('Chain name'), findsOneWidget);

    // Name it and save (a default timer is pre-populated).
    await tester.enterText(find.byType(TextField).first, 'Focus session');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back on the home list, the new chain appears.
    expect(find.text('Focus session'), findsOneWidget);
  });
}
