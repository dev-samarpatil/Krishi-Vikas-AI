import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/mandi_price_model.dart';

class MandiRepository {
  final Dio _dio = Dio();

  /// Fetches market prices for a given crop, state, and district.
  Future<List<MandiPriceModel>> fetchPrices(String crop, {String? state, String? district}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/api/market',
        queryParameters: {
          'crop': crop,
          if (state != null) 'state': state,
          if (district != null) 'district': district,
        },
        options: Options(headers: {'Bypass-Tunnel-Reminder': 'true'}),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['prices'] is List) {
        final List rawPrices = data['prices'];
        return rawPrices.map((p) => MandiPriceModel.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching mandi prices: $e");
      rethrow;
    }
  }
}
