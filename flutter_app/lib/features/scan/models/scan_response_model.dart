import '../../../shared/models/budget_item.dart';

class OrganicOption {
  final String description;
  final List<String> steps;

  const OrganicOption({
    required this.description,
    required this.steps,
  });

  factory OrganicOption.fromJson(Map<String, dynamic> json) {
    return OrganicOption(
      description: json['description'] as String? ?? '',
      steps: (json['steps'] as List? ?? []).map((e) => e as String).toList(),
    );
  }
}

class ScanResponseModel {
  final String diagnosisId;
  final String type;
  final String diseaseName;
  final String nameLocal;
  final double confidence;
  final String severity;
  final String urgency;
  final String explanation;
  final List<String> treatmentSteps;
  final OrganicOption organicOption;
  final String preventionTip;
  final List<BudgetItem> budgetItems;
  final double totalCostInr;
  final double organicTotalCostInr;
  final String? lowConfidenceNote;

  const ScanResponseModel({
    required this.diagnosisId,
    this.type = 'disease',
    required this.diseaseName,
    required this.nameLocal,
    required this.confidence,
    this.severity = 'medium',
    this.urgency = 'immediate',
    required this.explanation,
    required this.treatmentSteps,
    required this.organicOption,
    required this.preventionTip,
    required this.budgetItems,
    required this.totalCostInr,
    required this.organicTotalCostInr,
    this.lowConfidenceNote,
  });

  bool get isHealthy => type == 'healthy';
  bool get isInvalidImage => type == 'invalid_image';
  bool get isInconclusive => type == 'inconclusive';

  factory ScanResponseModel.fromJson(Map<String, dynamic> json) {
    return ScanResponseModel(
      diagnosisId: json['diagnosis_id'] as String? ?? '',
      type: json['type'] as String? ?? 'disease',
      diseaseName: json['name'] as String? ?? 'Unknown Disease',
      nameLocal: json['name_local'] as String? ?? 'अज्ञात रोग',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      severity: json['severity'] as String? ?? 'medium',
      urgency: json['urgency'] as String? ?? 'immediate',
      explanation: json['explanation'] as String? ?? '',
      treatmentSteps: (json['treatment_steps'] as List? ?? []).map((e) => e as String).toList(),
      organicOption: OrganicOption.fromJson(json['organic_option'] as Map<String, dynamic>? ?? {}),
      preventionTip: json['prevention'] as String? ?? '',
      budgetItems: (json['budget_items'] as List? ?? [])
          .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCostInr: (json['total_cost_inr'] as num? ?? 0.0).toDouble(),
      organicTotalCostInr: (json['organic_total_cost_inr'] as num? ?? 0.0).toDouble(),
      lowConfidenceNote: json['low_confidence_note'] as String?,
    );
  }
}
