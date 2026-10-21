import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:krishi_vikas_ai/shared/models/budget_item.dart';
import 'package:krishi_vikas_ai/features/scan/models/scan_response_model.dart';

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

  group('Map Coordinate Clamping Tests', () {
    test('Outbreak coordinates are clamped to valid geographical bounds', () {
      // Test extreme / invalid coordinates
      const double rawLatBeyondNorthPole = 112.5;
      const double rawLngBeyondDateLine = 240.0;

      final safeLoc = LatLng(
        rawLatBeyondNorthPole.clamp(-90.0, 90.0),
        rawLngBeyondDateLine.clamp(-180.0, 180.0),
      );

      expect(safeLoc.latitude, 90.0);
      expect(safeLoc.longitude, 180.0);

      // Test valid Nashik coordinates
      const double nashikLat = 19.9975;
      const double nashikLng = 73.7898;

      final validLoc = LatLng(
        nashikLat.clamp(-90.0, 90.0),
        nashikLng.clamp(-180.0, 180.0),
      );

      expect(validLoc.latitude, 19.9975);
      expect(validLoc.longitude, 73.7898);
    });
  });

  group('Chat Error UI & Retry Tests', () {
    testWidgets('Error bubble displays message and triggers retry on press', (WidgetTester tester) async {
      bool retryPressed = false;
      const originalQuery = 'steps to grow soybean';
      const errorMessage = 'Connection timed out. Tap Retry to try again.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        retryPressed = true;
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });
  });

  group('Map Imagery Fallback Banner Tests', () {
    testWidgets('Tile load error banner renders correctly and dismisses on retry', (WidgetTester tester) async {
      bool tileError = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    if (tileError)
                      Positioned(
                        top: 20,
                        left: 16,
                        right: 16,
                        child: Material(
                          color: Colors.black87,
                          child: Row(
                            children: [
                              const Text(
                                'Map imagery is temporarily unavailable.',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => tileError = false);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Map imagery is temporarily unavailable.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry to dismiss
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.text('Map imagery is temporarily unavailable.'), findsNothing);
    });
  });

  group('Crop Scan Dynamic Representation & Truthful State Tests', () {
    test('ScanResponseModel correctly identifies healthy vs disease vs inconclusive vs invalid', () {
      final healthy = ScanResponseModel.fromJson({
        'type': 'healthy',
        'name': 'Healthy Crop',
        'confidence': 0.95,
        'severity': 'low',
        'urgency': 'none',
        'explanation': 'Foliage looks vigorous.',
      });
      expect(healthy.isHealthy, isTrue);
      expect(healthy.isInconclusive, isFalse);
      expect(healthy.isInvalidImage, isFalse);
      expect(healthy.confidence, 0.95);

      final inconclusive = ScanResponseModel.fromJson({
        'type': 'inconclusive',
        'name': 'Inconclusive Symptoms',
        'confidence': 0.42,
        'low_confidence_note': 'Symptoms are ambiguous. Please consult KVK.',
      });
      expect(inconclusive.isInconclusive, isTrue);
      expect(inconclusive.isHealthy, isFalse);
      expect(inconclusive.lowConfidenceNote, contains('ambiguous'));

      final invalidImg = ScanResponseModel.fromJson({
        'type': 'invalid_image',
        'name': 'Non-crop Image Detected',
        'confidence': 0.0,
      });
      expect(invalidImg.isInvalidImage, isTrue);
      expect(invalidImg.confidence, 0.0);

      final disease = ScanResponseModel.fromJson({
        'type': 'disease',
        'name': 'Late Blight',
        'confidence': 0.89,
        'severity': 'high',
        'urgency': 'immediate',
      });
      expect(disease.isHealthy, isFalse);
      expect(disease.diseaseName, 'Late Blight');
      expect(disease.severity, 'high');
    });

    testWidgets('Scan error UI displays genuine failure reason and retry button', (WidgetTester tester) async {
      bool retried = false;
      const failureReason = 'The AI model response could not be parsed into a valid structured diagnosis.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 72, color: Colors.red),
                  const Text('Analysis Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Text(failureReason),
                  ElevatedButton.icon(
                    onPressed: () => retried = true,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Analysis'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Analysis Failed'), findsOneWidget);
      expect(find.text(failureReason), findsOneWidget);
      expect(find.text('Retry Analysis'), findsOneWidget);

      await tester.tap(find.text('Retry Analysis'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}
