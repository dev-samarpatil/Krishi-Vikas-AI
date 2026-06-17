/// Farm model — maps to Supabase `farms` table.
class FarmModel {
  final String id;
  final String userId;
  final String name;
  final String crop;
  final String? cropVariety;
  final String farmSize;
  final String sizeUnit;
  final String farmingType;
  final String? district;
  final String? state;
  final double? lat;
  final double? lng;
  final String? soilType;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;
  final String currentStage;
  final int soilScore;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FarmModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.crop,
    this.cropVariety,
    required this.farmSize,
    this.sizeUnit = 'acres',
    this.farmingType = 'conventional',
    this.district,
    this.state,
    this.lat,
    this.lng,
    this.soilType,
    this.sowingDate,
    this.expectedHarvestDate,
    this.currentStage = 'sowing',
    this.soilScore = 50,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      crop: json['crop'] as String,
      cropVariety: json['crop_variety'] as String?,
      farmSize: json['farm_size'] as String,
      sizeUnit: json['size_unit'] as String? ?? 'acres',
      farmingType: json['farming_type'] as String? ?? 'conventional',
      district: json['district'] as String?,
      state: json['state'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      soilType: json['soil_type'] as String?,
      sowingDate: json['sowing_date'] != null
          ? DateTime.parse(json['sowing_date'] as String)
          : null,
      expectedHarvestDate: json['expected_harvest_date'] != null
          ? DateTime.parse(json['expected_harvest_date'] as String)
          : null,
      currentStage: json['current_stage'] as String? ?? 'sowing',
      soilScore: json['soil_score'] as int? ?? 50,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'crop': crop,
    'crop_variety': cropVariety,
    'farm_size': farmSize,
    'size_unit': sizeUnit,
    'farming_type': farmingType,
    'district': district,
    'state': state,
    'lat': lat,
    'lng': lng,
    'soil_type': soilType,
    'sowing_date': sowingDate?.toIso8601String(),
    'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
    'current_stage': currentStage,
  };

  FarmModel copyWith({
    String? name,
    String? crop,
    String? currentStage,
    int? soilScore,
  }) {
    return FarmModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      crop: crop ?? this.crop,
      cropVariety: cropVariety,
      farmSize: farmSize,
      sizeUnit: sizeUnit,
      farmingType: farmingType,
      district: district,
      state: state,
      lat: lat,
      lng: lng,
      soilType: soilType,
      sowingDate: sowingDate,
      expectedHarvestDate: expectedHarvestDate,
      currentStage: currentStage ?? this.currentStage,
      soilScore: soilScore ?? this.soilScore,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  double get latWithFallback {
    if (lat != null) return lat!;
    final dist = district?.toLowerCase() ?? '';
    if (dist.contains('palghar')) return 19.6983;
    if (dist.contains('pune')) return 18.5204;
    if (dist.contains('nashik')) return 20.0110;
    if (dist.contains('thane')) return 19.2183;
    return 19.3919; // default Vasai-Virar
  }

  double get lngWithFallback {
    if (lng != null) return lng!;
    final dist = district?.toLowerCase() ?? '';
    if (dist.contains('palghar')) return 72.7656;
    if (dist.contains('pune')) return 73.8567;
    if (dist.contains('nashik')) return 73.7903;
    if (dist.contains('thane')) return 72.9781;
    return 72.8397; // default Vasai-Virar
  }
}
