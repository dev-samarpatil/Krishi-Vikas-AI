import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Service for local storage operations via Hive.
/// Used for caching, auth tokens, and offline data.
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  Box get _settings => Hive.box(AppConstants.settingsBox);
  Box get _cache => Hive.box(AppConstants.cacheBox);

  // ── Language ──────────────────────────────────────────────────────
  String get selectedLanguage =>
      _settings.get(AppConstants.selectedLanguageKey, defaultValue: 'en');

  Future<void> setSelectedLanguage(String langCode) =>
      _settings.put(AppConstants.selectedLanguageKey, langCode);

  // ── Onboarding ────────────────────────────────────────────────────
  bool get hasCompletedOnboarding =>
      _settings.get('has_completed_onboarding', defaultValue: false);

  Future<void> setHasCompletedOnboarding(bool value) =>
      _settings.put('has_completed_onboarding', value);

  // ── Selected Farm ─────────────────────────────────────────────────
  String? get selectedFarmId =>
      _settings.get(AppConstants.selectedFarmIdKey);

  Future<void> setSelectedFarmId(String farmId) =>
      _settings.put(AppConstants.selectedFarmIdKey, farmId);

  // ── Guest Mode User ID ─────────────────────────────────────────────
  String? get guestUserId => _settings.get('guest_user_id');

  Future<void> setGuestUserId(String id) => _settings.put('guest_user_id', id);

  // ── Guest Mode Farms ───────────────────────────────────────────────
  List<dynamic>? get guestFarmsJson => _cache.get('guest_farms');

  Future<void> setGuestFarmsJson(List<dynamic> jsonList) =>
      _cache.put('guest_farms', jsonList);

  // ── FCM Token ─────────────────────────────────────────────────────
  String? get fcmToken => _settings.get(AppConstants.fcmTokenKey);

  Future<void> setFcmToken(String token) =>
      _settings.put(AppConstants.fcmTokenKey, token);

  // ── Generic Cache ─────────────────────────────────────────────────
  dynamic getCached(String key) => _cache.get(key);

  Future<void> setCache(String key, dynamic value) =>
      _cache.put(key, value);

  Future<void> clearCache() => _cache.clear();
}
