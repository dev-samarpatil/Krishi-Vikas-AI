import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/farm_model.dart';
import '../../../shared/models/diagnosis_model.dart';
import '../../../shared/services/local_storage_service.dart';
import '../data/farm_repository.dart';

// ── Repository provider ──────────────────────────────────────────────
final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepository.instance;
});

// ── All farms for the current user ───────────────────────────────────
final farmsProvider = FutureProvider<List<FarmModel>>((ref) async {
  final repo = ref.watch(farmRepositoryProvider);
  return repo.fetchFarms();
});

// ── Selected farm ID (persisted in Hive) ─────────────────────────────
final selectedFarmIdProvider =
    StateNotifierProvider<SelectedFarmNotifier, String?>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return SelectedFarmNotifier(localStorage);
});

class SelectedFarmNotifier extends StateNotifier<String?> {
  final LocalStorageService _localStorage;

  SelectedFarmNotifier(this._localStorage)
      : super(_localStorage.selectedFarmId);

  void select(String farmId) {
    state = farmId;
    _localStorage.setSelectedFarmId(farmId);
  }
}

// ── Derived: currently selected farm model ───────────────────────────
final selectedFarmProvider = Provider<FarmModel?>((ref) {
  final farms = ref.watch(farmsProvider).valueOrNull ?? [];
  final selectedId = ref.watch(selectedFarmIdProvider);

  if (farms.isEmpty) return null;

  // If no farm is selected yet, auto-select the first one
  if (selectedId == null) {
    // Schedule the side-effect after the current build
    Future.microtask(() {
      ref.read(selectedFarmIdProvider.notifier).select(farms.first.id);
    });
    return farms.first;
  }

  // Find the selected farm, fallback to first
  return farms.firstWhere(
    (f) => f.id == selectedId,
    orElse: () => farms.first,
  );
});

// ── Diagnoses for a specific farm ────────────────────────────────────
final farmDiagnosesProvider =
    FutureProvider.family<List<DiagnosisModel>, String>((ref, farmId) async {
  final repo = ref.watch(farmRepositoryProvider);
  return repo.fetchDiagnoses(farmId);
});
