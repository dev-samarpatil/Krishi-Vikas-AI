import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../farm/providers/farm_provider.dart';

class OutbreakAlert {
  final String title;
  final String message;
  final String severity;

  const OutbreakAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}

final alertProvider = FutureProvider<List<OutbreakAlert>>((ref) async {
  final selectedFarm = ref.watch(selectedFarmProvider);
  
  if (selectedFarm == null) {
    return [];
  }

  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));

  // Simulate returning an alert based on crop
  if (selectedFarm.crop.toLowerCase() == 'tomato') {
    return [
      const OutbreakAlert(
        title: 'Fall Armyworm Outbreak',
        message: '6 severe Fall Armyworm cases reported near your location.',
        severity: 'high',
      ),
    ];
  }

  return [];
});
