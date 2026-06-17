import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised app constants — all magic strings and config values live here.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────
  static const String appName = 'Krishi Vikas AI';
  static const String appVersion = '2.0.0';

  // ── Hive Box Names ────────────────────────────────────────────────
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String authBox = 'auth';

  // ── Hive Keys ─────────────────────────────────────────────────────
  static const String jwtTokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String selectedLanguageKey = 'selected_language';
  static const String selectedFarmIdKey = 'selected_farm_id';
  static const String fcmTokenKey = 'fcm_token';

  // ── Environment Variables (from .env via flutter_dotenv) ─────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static String get roboflowApiKey => dotenv.env['ROBOFLOW_API_KEY'] ?? '';
  static String get roboflowModelId => dotenv.env['ROBOFLOW_MODEL_ID'] ?? '';
  static const String baseUrl = 'https://krishi-vikas-ai.onrender.com';

  // ── API Endpoints (relative to apiBaseUrl) ───────────────────────
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String farms = '/farms';
  static const String scan = '/scan';
  static const String chat = '/chat';
  static const String mandiPrices = '/mandi/prices';
  static const String weather = '/weather';
  static const String schemes = '/schemes';
  static const String pushRegister = '/push/register';
  static const String kvkNearest = '/kvk/nearest';

  // ── Supported Locales (EN, HI, MR, TA) ──────────────────────────
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
    Locale('ta'), // Tamil
  ];

  // ── Crop Options ─────────────────────────────────────────────────
  static const List<String> cropOptions = [
    'corn',
    'pepper bell',
    'potato',
    'rice',
    'sugarcane',
    'tomato',
    'wheat',
    'other',
  ];

  // ── Farm Size Options ────────────────────────────────────────────
  static const List<String> farmSizeOptions = [
    '<1',
    '1-2',
    '2-5',
    '5-10',
    '10+',
  ];

  // ── Farming Type Options ─────────────────────────────────────────
  static const List<String> farmingTypeOptions = [
    'organic',
    'conventional',
    'mixed',
  ];

  // ── Crop Growth Stages ───────────────────────────────────────────
  static const List<String> growthStages = [
    'sowing',
    'germination',
    'vegetative',
    'flowering',
    'harvest',
  ];

  // ── Scan Confidence Threshold ────────────────────────────────────
  static const double scanConfidenceThreshold = 70.0;

  // ── Soil Score ───────────────────────────────────────────────────
  static const int defaultSoilScore = 50;
  static const int organicTreatmentBonus = 10;
  static const int chemicalTreatmentBonus = 2;

  // ── Max Limits ───────────────────────────────────────────────────
  static const int maxFarmsPerUser = 5;
  static const int maxImageSizeMb = 5;
}
