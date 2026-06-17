/// Market (Mandi) price model for a specific crop.
class MandiPriceModel {
  final String crop;
  final double price;
  final String unit;
  final bool isUp; // trend indicator

  const MandiPriceModel({
    required this.crop,
    required this.price,
    required this.unit,
    required this.isUp,
  });

  factory MandiPriceModel.fromJson(Map<String, dynamic> json) {
    final trendStr = json['trend'] as String?;
    bool trendBool = true;
    if (trendStr != null) {
      trendBool = trendStr.toLowerCase() == 'up' || trendStr.toLowerCase() == 'flat';
    } else {
      trendBool = json['is_up'] as bool? ?? true;
    }

    return MandiPriceModel(
      crop: json['crop'] as String? ?? json['market'] as String? ?? 'Crop',
      price: (json['modal_price'] ?? json['price'] as num? ?? 0.0).toDouble(),
      unit: json['unit'] as String? ?? 'qtl',
      isUp: trendBool,
    );
  }
}
