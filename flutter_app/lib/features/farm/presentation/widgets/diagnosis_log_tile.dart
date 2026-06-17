import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/diagnosis_model.dart';

/// A card-style tile that renders a single diagnosis entry.
///
/// Shows disease name, crop, confidence bar, severity chip, and date.
class DiagnosisLogTile extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final VoidCallback? onTap;

  const DiagnosisLogTile({
    super.key,
    required this.diagnosis,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(diagnosis.createdAt);
    final isHealthy = diagnosis.diseaseName == null ||
        diagnosis.diseaseName!.toLowerCase() == 'healthy';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isHealthy
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning_rounded,
                  color: isHealthy ? AppTheme.successGreen : AppTheme.errorRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHealthy
                          ? 'Healthy'
                          : diagnosis.diseaseName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${diagnosis.crop[0].toUpperCase()}${diagnosis.crop.substring(1)} • $dateStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    // Confidence bar
                    if (diagnosis.confidence != null) ...[
                      const SizedBox(height: 6),
                      _ConfidenceBar(confidence: diagnosis.confidence!),
                    ],
                  ],
                ),
              ),

              // Severity chip and Treatment type
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (diagnosis.severity != null)
                    _SeverityChip(severity: diagnosis.severity!),
                  if (diagnosis.treatmentType != null && diagnosis.treatmentType!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _TreatmentChip(treatmentType: diagnosis.treatmentType!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final fraction = (confidence / 100).clamp(0.0, 1.0);
    final color = confidence >= 70
        ? AppTheme.successGreen
        : confidence >= 40
            ? AppTheme.warningYellow
            : AppTheme.errorRed;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppTheme.dividerGray.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${confidence.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    switch (severity.toLowerCase()) {
      case 'high':
        chipColor = AppTheme.errorRed;
        break;
      case 'medium':
        chipColor = AppTheme.accentOrange;
        break;
      default:
        chipColor = AppTheme.warningYellow;
    }

    return Container(
      margin: const EdgeInsets.only(left: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        severity[0].toUpperCase() + severity.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}

class _TreatmentChip extends StatelessWidget {
  final String treatmentType;
  const _TreatmentChip({required this.treatmentType});

  @override
  Widget build(BuildContext context) {
    final bool isOrganic = treatmentType.toLowerCase() == 'organic';
    final Color chipColor = isOrganic ? AppTheme.successGreen : AppTheme.accentOrange;

    return Container(
      margin: const EdgeInsets.only(left: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOrganic ? Icons.eco : Icons.science,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            treatmentType[0].toUpperCase() + treatmentType.substring(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
