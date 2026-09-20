import 'package:family_budget_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('app starts and shows the home title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FamilyBudgetApp(home: Scaffold(body: Text('Aile Bütçesi'))),
      ),
    );

    expect(find.text('Aile Bütçesi'), findsOneWidget);
  });
}
