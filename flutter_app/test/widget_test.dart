import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_vikas_ai/shared/models/budget_item.dart';
import 'package:krishi_vikas_ai/features/scan/presentation/providers/scan_provider.dart';

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

  group('Crop Scan Dio Error Handling & Status Code Mapping Tests', () {
    test('HTTP 500 maps to user-friendly server error message without leaking DioException', () {
      final dioException500 = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/diagnose'),
          statusCode: 500,
          data: {
            'success': false,
            'status': 'server_error',
            'error': {
              'code': 'DIAGNOSIS_FAILED',
              'message': 'Crop diagnosis encountered an unexpected server error.',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final msg = getReadableScanErrorMessage(dioException500);
      expect(msg, 'Crop diagnosis encountered an unexpected server error.');
      expect(msg, isNot(contains('DioException')));
      expect(msg, isNot(contains('500')));
    });

    test('HTTP 429 maps to user-friendly quota/busy message', () {
      final dioException429 = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/diagnose'),
          statusCode: 429,
          data: {
            'success': false,
            'status': 'rate_limited',
            'error': {
              'code': 'AI_QUOTA_EXCEEDED',
              'message': 'Crop analysis service is temporarily busy or free quota has been reached.',
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final msg = getReadableScanErrorMessage(dioException429);
      expect(msg, contains('temporarily busy'));
    });

    test('HTTP 400 invalid image maps to clearer photo message', () {
      final dioException400 = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/diagnose'),
          statusCode: 400,
          data: {
            'success': false,
            'error': 'Invalid image format',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final msg = getReadableScanErrorMessage(dioException400);
      expect(msg, 'Invalid image format');
    });

    test('Connection error maps to network check message', () {
      final dioConnError = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        type: DioExceptionType.connectionError,
      );

      final msg = getReadableScanErrorMessage(dioConnError);
      expect(msg, contains('Unable to connect to the server'));
    });

    test('Connection timeout maps to upload timeout message', () {
      final dioTimeout = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        type: DioExceptionType.connectionTimeout,
      );

      final msg = getReadableScanErrorMessage(dioTimeout);
      expect(msg, contains('Connection timed out'));
    });

    test('Cancellation maps to cancelled message', () {
      final dioCancel = DioException(
        requestOptions: RequestOptions(path: '/api/diagnose'),
        type: DioExceptionType.cancel,
      );

      final msg = getReadableScanErrorMessage(dioCancel);
      expect(msg, contains('cancelled'));
    });

    test('FormatException maps to invalid response format message', () {
      const formatErr = FormatException('Unexpected character at line 1');
      final msg = getReadableScanErrorMessage(formatErr);
      expect(msg, contains('invalid response format'));
    });
  });
}
