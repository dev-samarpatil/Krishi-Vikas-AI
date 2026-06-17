import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/local_storage_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return LocaleNotifier(localStorage);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _localStorage;

  LocaleNotifier(this._localStorage)
      : super(_loadInitialLocale(_localStorage));

  static Locale _loadInitialLocale(LocalStorageService storage) {
    final code = storage.selectedLanguage;
    return Locale(code);
  }

  void setLocale(Locale locale) {
    if (!AppConstants.supportedLocales.contains(locale)) return;
    state = locale;
    _localStorage.setSelectedLanguage(locale.languageCode);
  }
}
