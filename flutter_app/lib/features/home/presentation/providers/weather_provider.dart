import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/weather_model.dart';
import '../../../farm/providers/farm_provider.dart';
import '../../data/weather_repository.dart';

import '../../../../shared/providers/locale_provider.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

final weatherProvider = FutureProvider<WeatherModel?>((ref) async {
  final selectedFarm = ref.watch(selectedFarmProvider);
  final locale = ref.watch(localeProvider);
  
  // Use Vasai, Maharashtra (19.3919, 72.8397) as fallback when GPS/farm coordinates are null
  final lat = selectedFarm?.latWithFallback ?? 19.3919;
  final lng = selectedFarm?.lngWithFallback ?? 72.8397;

  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetchWeather(lat, lng, locale.languageCode);
});
