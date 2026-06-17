import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/mandi_price_model.dart';
import '../../../farm/providers/farm_provider.dart';
import '../../../mandi/data/mandi_repository.dart';

final mandiRepositoryProvider = Provider<MandiRepository>((ref) {
  return MandiRepository();
});

final mandiProvider = FutureProvider<List<MandiPriceModel>>((ref) async {
  final selectedFarm = ref.watch(selectedFarmProvider);
  
  if (selectedFarm == null) {
    return [];
  }

  final repo = ref.watch(mandiRepositoryProvider);
  return repo.fetchPrices(
    selectedFarm.crop,
    state: selectedFarm.state,
    district: selectedFarm.district,
  );
});
