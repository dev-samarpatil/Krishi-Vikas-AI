import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/farm_model.dart';
import '../../../shared/models/diagnosis_model.dart';
import '../../../shared/services/local_storage_service.dart';
import '../../../core/supabase_client.dart';

/// Repository that encapsulates all Supabase CRUD operations for farms
/// and diagnoses. Used by Riverpod providers — never called directly from UI.
class FarmRepository {
  FarmRepository._();
  static final FarmRepository instance = FarmRepository._();

  SupabaseClient get _client => SupabaseClientService.instance.client;

  String _getOrCreateGuestUserId() {
    final storage = LocalStorageService();
    String? guestId = storage.guestUserId;
    if (guestId == null) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      values[6] = (values[6] & 0x0f) | 0x40; // Version 4
      values[8] = (values[8] & 0x3f) | 0x80; // Variant RFC4122
      final buffer = StringBuffer();
      for (int i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
          buffer.write('-');
        }
        buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
      }
      guestId = buffer.toString();
      storage.setGuestUserId(guestId);
    }
    return guestId;
  }

  // ── Farms ──────────────────────────────────────────────────────────

  /// Fetch all farms for the current authenticated user or local guest farms.
  Future<List<FarmModel>> fetchFarms() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // Guest Mode: fetch from local storage
      final storage = LocalStorageService();
      final cachedList = storage.guestFarmsJson;
      if (cachedList == null) return [];
      return cachedList
          .map((json) => FarmModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    final response = await _client
        .from('farms')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => FarmModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new farm and return the created model.
  Future<FarmModel> createFarm({
    required String name,
    required String crop,
    required String farmSize,
    required String farmingType,
    String? district,
    String? state,
    double? lat,
    double? lng,
    DateTime? sowingDate,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      // Guest Mode: create locally and save in Hive
      final guestId = _getOrCreateGuestUserId();
      
      // Generate unique farm ID locally
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      values[6] = (values[6] & 0x0f) | 0x40;
      values[8] = (values[8] & 0x3f) | 0x80;
      final buffer = StringBuffer();
      for (int i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
          buffer.write('-');
        }
        buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
      }
      final newFarmId = buffer.toString();

      final now = DateTime.now();
      final farm = FarmModel(
        id: newFarmId,
        userId: guestId,
        name: name,
        crop: crop,
        farmSize: farmSize,
        farmingType: farmingType,
        district: district,
        state: state,
        lat: lat,
        lng: lng,
        sowingDate: sowingDate,
        createdAt: now,
        updatedAt: now,
      );

      final storage = LocalStorageService();
      final list = storage.guestFarmsJson ?? [];
      final newList = List<dynamic>.from(list)..add(farm.toJson()..addAll({
        'id': farm.id,
        'user_id': farm.userId,
        'created_at': farm.createdAt.toIso8601String(),
        'updated_at': farm.updatedAt.toIso8601String(),
        'current_stage': farm.currentStage,
        'soil_score': farm.soilScore,
        'is_active': farm.isActive,
      }));
      await storage.setGuestFarmsJson(newList);
      return farm;
    }

    final userId = currentUser.id;

    final data = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'crop': crop,
      'farm_size': farmSize,
      'farming_type': farmingType,
      'district': district,
      'state': state,
      'lat': lat,
      'lng': lng,
      'sowing_date': sowingDate?.toIso8601String().split('T').first,
      'current_stage': 'sowing',
      'soil_score': 50,
    };

    final response = await _client
        .from('farms')
        .insert(data)
        .select()
        .single();

    return FarmModel.fromJson(response);
  }

  /// Update an existing farm.
  Future<FarmModel> updateFarm(String farmId, Map<String, dynamic> data) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      // Guest Mode: update locally in Hive
      final storage = LocalStorageService();
      final list = storage.guestFarmsJson ?? [];
      final newList = <dynamic>[];
      FarmModel? updatedFarm;

      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map['id'] == farmId) {
          data.forEach((key, value) {
            map[key] = value;
          });
          map['updated_at'] = DateTime.now().toIso8601String();
          updatedFarm = FarmModel.fromJson(map);
          newList.add(map);
        } else {
          newList.add(item);
        }
      }

      if (updatedFarm == null) {
        throw Exception('Farm not found locally');
      }

      await storage.setGuestFarmsJson(newList);
      return updatedFarm;
    }

    final response = await _client
        .from('farms')
        .update(data)
        .eq('id', farmId)
        .select()
        .single();

    return FarmModel.fromJson(response);
  }

  /// Delete a farm
  Future<void> deleteFarm(String farmId) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      // Guest Mode: delete locally in Hive
      final storage = LocalStorageService();
      final list = storage.guestFarmsJson ?? [];
      final newList = list.where((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return map['id'] != farmId;
      }).toList();

      await storage.setGuestFarmsJson(newList);
      return;
    }

    await _client.from('farms').delete().eq('id', farmId);
  }

  // ── Diagnoses ──────────────────────────────────────────────────────

  /// Fetch all diagnoses for a specific farm, newest first.
  Future<List<DiagnosisModel>> fetchDiagnoses(String farmId) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      // Guest Mode: fetch from local Hive cache, filtered by farmId
      final storage = LocalStorageService();
      final list = storage.guestDiagnosesJson ?? [];
      final filtered = list
          .where((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return map['farm_id'] == farmId;
          })
          .map((json) =>
              DiagnosisModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      // Sort newest first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    final response = await _client
        .from('diagnoses')
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DiagnosisModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
