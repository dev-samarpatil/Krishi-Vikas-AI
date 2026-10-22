import 'package:dio/dio.dart';
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

String getReadableScanErrorMessage(dynamic error) {
  if (error is DioException) {
    // 1. Inspect backend structured JSON error
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] is Map<String, dynamic> && data['error']['message'] != null) {
          final msg = data['error']['message'].toString();
          if (msg.isNotEmpty) return msg;
        } else if (data['error'] is String && (data['error'] as String).isNotEmpty) {
          return data['error'] as String;
        } else if (data['detail'] is String && (data['detail'] as String).isNotEmpty) {
          return data['detail'] as String;
        }
      }
    }

    // 2. Map HTTP status codes to user-friendly messages
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return 'This image could not be processed. Please select or capture a clearer image.';
        case 413:
          return 'The selected image is too large. Please select a smaller photo.';
        case 415:
          return 'Unsupported file format. Please upload a JPEG, PNG, or WEBP crop image.';
        case 422:
          return 'Incomplete scan request. Please ensure all farm details are configured.';
        case 429:
          return 'Crop analysis is temporarily busy. Please try again in a few moments.';
        case 502:
          return 'AI analysis produced an unparseable response. Please take a clearer photo and try again.';
        case 503:
          return 'Crop analysis is temporarily unavailable. Please try again shortly.';
        case 500:
        default:
          return "We couldn't analyze your crop right now. Please try again shortly.";
      }
    }

    // 3. Map Dio network and transport failures
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out while uploading the image. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Analysis is taking longer than expected. Please check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Check your internet connection.';
      case DioExceptionType.cancel:
        return 'Crop analysis request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Security verification failed. Please try again later.';
      case DioExceptionType.badResponse:
        return "We couldn't analyze your crop right now. Please try again shortly.";
      case DioExceptionType.unknown:
        return 'Unable to connect to the server. Check your internet connection.';
    }
  }

  if (error is FormatException) {
    return 'Received an invalid response format from the server. Please try again.';
  }

  final clean = error.toString().replaceAll('Exception: ', '').trim();
  return clean.isNotEmpty ? clean : "We couldn't analyze your crop right now. Please try again shortly.";
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
    // Prevent duplicate simultaneous requests
    if (state.status == ScanStatus.loading) return;

    final image = state.imageFile;
    if (image == null) return;

    state = state.copyWith(status: ScanStatus.loading, errorMessage: null);

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
        errorMessage: getReadableScanErrorMessage(e),
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
