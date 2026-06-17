/// Diagnosis model — maps to Supabase `diagnoses` table.
class DiagnosisModel {
  final String id;
  final String farmId;
  final String userId;
  final String? imageUrl;
  final String crop;
  final String? diseaseName;
  final double? confidence;
  final String? modelUsed; // 'roboflow' | 'gemini'
  final String? severity;  // 'low' | 'medium' | 'high'
  final String? treatmentType; // 'organic' | 'chemical'
  final List<Map<String, dynamic>>? treatmentSteps;
  final List<Map<String, dynamic>>? costEstimate;
  final String? preventionTip;
  final String language;
  final Map<String, dynamic>? weatherAtScan;
  final DateTime createdAt;

  const DiagnosisModel({
    required this.id,
    required this.farmId,
    required this.userId,
    this.imageUrl,
    required this.crop,
    this.diseaseName,
    this.confidence,
    this.modelUsed,
    this.severity,
    this.treatmentType,
    this.treatmentSteps,
    this.costEstimate,
    this.preventionTip,
    this.language = 'en',
    this.weatherAtScan,
    required this.createdAt,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String?,
      crop: json['crop'] as String,
      diseaseName: json['disease_name'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      modelUsed: json['model_used'] as String?,
      severity: json['severity'] as String?,
      treatmentType: json['treatment_chosen'] as String?,
      treatmentSteps: (json['treatment_steps'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      costEstimate: (json['cost_estimate'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      preventionTip: json['prevention_tip'] as String?,
      language: json['language'] as String? ?? 'en',
      weatherAtScan: json['weather_at_scan'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Whether the result is from the primary Roboflow CNN model.
  bool get isRoboflowResult => modelUsed == 'roboflow';

  /// Whether confidence is high enough to display the bar.
  bool get showConfidenceBar => (confidence ?? 0) >= 70;
}
