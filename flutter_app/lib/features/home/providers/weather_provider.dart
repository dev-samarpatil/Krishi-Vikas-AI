import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/weather_model.dart';
import '../../farm/providers/farm_provider.dart';
import '../data/weather_repository.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

final weatherProvider = FutureProvider<WeatherModel?>((ref) async {
  final selectedFarm = ref.watch(selectedFarmProvider);
  
  if (selectedFarm == null || selectedFarm.lat == null || selectedFarm.lng == null) {
    return null; // Return null if no location is available for the farm
  }

  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetchWeather(selectedFarm.lat!, selectedFarm.lng!, 'en');
});
