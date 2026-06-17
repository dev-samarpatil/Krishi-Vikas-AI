import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_vikas_ai/shared/models/budget_item.dart';

void main() {
  group('BudgetItem Model Tests', () {
    test('fromJson should parse valid JSON correctly', () {
      final json = {
        'item': 'Neem Oil',
        'quantity': '1 Litre',
        'price_inr': 450,
      };

      final budgetItem = BudgetItem.fromJson(json);

      expect(budgetItem.item, 'Neem Oil');
      expect(budgetItem.quantity, '1 Litre');
      expect(budgetItem.priceInr, 450.0);
    });

    test('toJson should convert BudgetItem to JSON correctly', () {
      const budgetItem = BudgetItem(
        item: 'Mancozeb Fungicide',
        quantity: '500g',
        priceInr: 280.0,
      );

      final json = budgetItem.toJson();

      expect(json['item'], 'Mancozeb Fungicide');
      expect(json['quantity'], '500g');
      expect(json['price_inr'], 280.0);
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('Renders simple mock UI component successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test Screen')),
            body: const Center(
              child: Text('Welcome to Krishi Vikas AI'),
            ),
          ),
        ),
      );

      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.text('Welcome to Krishi Vikas AI'), findsOneWidget);
    });
  });
}
