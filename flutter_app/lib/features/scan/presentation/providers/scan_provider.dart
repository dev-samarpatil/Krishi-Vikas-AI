import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import '../../../../shared/models/kvk_model.dart';
import '../../../../shared/repositories/scan_repository.dart';
import '../../../farm/providers/farm_provider.dart';
import '../../../home/presentation/providers/weather_provider.dart';
import '../../models/scan_response_model.dart';

enum ScanStatus { initial, loading, success, error }

class ScanState {
  final ScanStatus status;
  final ScanResponseModel? result;
  final String? errorMessage;
  final XFile? imageFile;

  const ScanState({
    required this.status,
    this.result,
    this.errorMessage,
    this.imageFile,
  });

  ScanState copyWith({
    ScanStatus? status,
    ScanResponseModel? result,
    String? errorMessage,
    XFile? imageFile,
  }) {
    return ScanState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      imageFile: imageFile ?? this.imageFile,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  final ScanRepository _repository;

  ScanNotifier(this._ref, this._repository)
      : super(const ScanState(status: ScanStatus.initial));

  void setImage(XFile file) {
    state = state.copyWith(imageFile: file, status: ScanStatus.initial);
  }

  void reset() {
    state = const ScanState(status: ScanStatus.initial);
  }

  Future<void> runScan() async {
    final image = state.imageFile;
    if (image == null) return;

    state = state.copyWith(status: ScanStatus.loading);

    try {
      final selectedFarm = _ref.read(selectedFarmProvider);
      if (selectedFarm == null) {
        throw Exception('Please select or configure a farm first.');
      }

      // Get weather summary
      final weather = _ref.read(weatherProvider).valueOrNull;
      final weatherSummary = weather != null
          ? '${weather.temp.round()}°C, ${weather.condition}'
          : 'Normal';

      // Determine language
      const language = 'en'; 

      final result = await _repository.scanCrop(
        imageFile: image,
        crop: selectedFarm.crop,
        district: selectedFarm.district ?? 'Unknown',
        state: selectedFarm.state ?? 'Unknown',
        soilType: selectedFarm.soilType ?? 'Unknown',
        weatherSummary: weatherSummary,
        stage: selectedFarm.currentStage,
        language: language,
        farmId: selectedFarm.id,
      );

      state = state.copyWith(status: ScanStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final repo = ref.watch(scanRepositoryProvider);
  return ScanNotifier(ref, repo);
});

final kvkListProvider = FutureProvider<List<KvkModel>>((ref) async {
  final repo = ref.watch(scanRepositoryProvider);
  final farm = ref.watch(selectedFarmProvider);
  
  final lat = farm?.latWithFallback ?? 19.1158;
  final lng = farm?.lngWithFallback ?? 72.8777;

  return repo.getNearestKvks(lat, lng);
});
