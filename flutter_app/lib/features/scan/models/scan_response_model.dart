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
  final String diseaseName;
  final String nameLocal;
  final double confidence;
  final String explanation;
  final List<String> treatmentSteps;
  final OrganicOption organicOption;
  final String preventionTip;
  final List<BudgetItem> budgetItems;
  final double totalCostInr;
  final double organicTotalCostInr;

  const ScanResponseModel({
    required this.diagnosisId,
    required this.diseaseName,
    required this.nameLocal,
    required this.confidence,
    required this.explanation,
    required this.treatmentSteps,
    required this.organicOption,
    required this.preventionTip,
    required this.budgetItems,
    required this.totalCostInr,
    required this.organicTotalCostInr,
  });

  factory ScanResponseModel.fromJson(Map<String, dynamic> json) {
    return ScanResponseModel(
      diagnosisId: json['diagnosis_id'] as String? ?? '',
      diseaseName: json['name'] as String? ?? 'Unknown Disease',
      nameLocal: json['name_local'] as String? ?? 'अज्ञात रोग',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      explanation: json['explanation'] as String? ?? '',
      treatmentSteps: (json['treatment_steps'] as List? ?? []).map((e) => e as String).toList(),
      organicOption: OrganicOption.fromJson(json['organic_option'] as Map<String, dynamic>? ?? {}),
      preventionTip: json['prevention'] as String? ?? '',
      budgetItems: (json['budget_items'] as List? ?? [])
          .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCostInr: (json['total_cost_inr'] as num? ?? 0.0).toDouble(),
      organicTotalCostInr: (json['organic_total_cost_inr'] as num? ?? 0.0).toDouble(),
    );
  }
}
