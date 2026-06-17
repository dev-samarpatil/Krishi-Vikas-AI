import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' show XFile;

import '../../core/constants/app_constants.dart';
import '../../core/supabase_client.dart';
import '../models/budget_item.dart';
import '../models/kvk_model.dart';
import '../../features/scan/models/scan_response_model.dart';

import 'package:flutter/foundation.dart' show kIsWeb, compute;

Uint8List _compressImage(Uint8List bytes) {
  final decodedImage = img.decodeImage(bytes);
  if (decodedImage == null) return bytes;
  
  final resized = img.copyResize(
    decodedImage,
    width: decodedImage.width > decodedImage.height ? 800 : null,
    height: decodedImage.height >= decodedImage.width ? 800 : null,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository();
});

class ScanRepository {
  final Dio _dio;

  ScanRepository() : _dio = Dio();

  SupabaseClient get _supabase => SupabaseClientService.instance.client;

  /// Compresses the image and uploads it to the `/api/diagnose` endpoint.
  Future<ScanResponseModel> scanCrop({
    required XFile imageFile,
    required String crop,
    required String district,
    required String state,
    required String soilType,
    required String weatherSummary,
    required String stage,
    required String language,
    required String farmId,
  }) async {
    final bytes = await imageFile.readAsBytes();
    
    // Run compression in a background isolate to prevent UI freezing
    final compressedBytes = await compute(_compressImage, bytes);
    
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    const lat = 19.99;
    const long = 73.79;

    MultipartFile multipartFile;
    if (kIsWeb) {
      // Send as base64 string to backend
      final base64Image = base64Encode(compressedBytes);
      multipartFile = MultipartFile.fromString(
        base64Image,
        filename: 'crop_image.jpg',
      );
    } else {
      final tempDir = await Directory.systemTemp.createTemp();
      final compressedFile = File('${tempDir.path}/temp_compressed.jpg')
        ..writeAsBytesSync(compressedBytes);
      multipartFile = await MultipartFile.fromFile(
        compressedFile.path,
        filename: 'crop_image.jpg',
      );
    }

    final formData = FormData.fromMap({
      'image': multipartFile,
      'lat': lat,
      'long': long,
      'crop_type': crop,
      'language': language,
      'farmer_id': userId,
      'farm_size': '1-2',
      'farming_type': 'organic',
      'farm_id': farmId,
    });

    final baseUrl = AppConstants.baseUrl;

    try {
      final response = await _dio.post(
        '$baseUrl/api/diagnose',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Bypass-Tunnel-Reminder': 'true',
          },
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      if (response.statusCode == 200) {
        return ScanResponseModel.fromJson(response.data);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Scan API Error: $e');
      rethrow;
    }
  }

  /// Saves the diagnosis treatment choice to farm logs
  Future<void> saveToFarmLog({
    required String diagnosisId,
    required String treatmentType,
  }) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final baseUrl = AppConstants.baseUrl;

    try {
      await _dio.post(
        '$baseUrl/api/log-treatment',
        data: {
          'farmer_id': userId,
          'diagnosis_id': diagnosisId,
          'treatment_type': treatmentType,
        },
        options: Options(headers: {'Bypass-Tunnel-Reminder': 'true'}),
      );
    } catch (e) {
      print('Log treatment API failed: $e.');
    }
  }

  /// Fetches nearest KVKs
  Future<List<KvkModel>> getNearestKvks(double lat, double lng) async {
    final baseUrl = AppConstants.baseUrl; 


    try {
      final response = await _dio.get(
        '$baseUrl/api/nearest-kvk',
        queryParameters: {
          'lat': lat,
          'long': lng,
          'limit': 3,
        },
        options: Options(headers: {'Bypass-Tunnel-Reminder': 'true'}),
      );
      final list = response.data['kvks'] as List;
      return list.map((e) => KvkModel.fromJson(e)).toList();
    } catch (e) {
      print('KVK API failed: $e. Using local mock list.');
      return const [
        KvkModel(name: 'Krishi Vigyan Kendra, Vasai', distance: 8.4, phone: '0250-2348574', address: 'Vasai Road, Palghar'),
        KvkModel(name: 'Krishi Vigyan Kendra, Thane', distance: 24.2, phone: '022-25403487', address: 'Mulund East, Thane'),
        KvkModel(name: 'Krishi Vigyan Kendra, Palghar', distance: 42.1, phone: '02525-256034', address: 'Shirgaon, Palghar'),
      ];
    }
  }
}
