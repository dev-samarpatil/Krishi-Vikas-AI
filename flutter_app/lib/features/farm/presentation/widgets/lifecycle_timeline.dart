import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Horizontal 5-stage crop lifecycle timeline.
///
/// Renders: Sowing → Germination → Vegetative → Flowering → Harvest
/// with green filled circles for completed stages, a pulsing outline
/// for the current stage, and grey circles for future stages.
class LifecycleTimeline extends StatelessWidget {
  /// The current growth stage key (e.g. 'sowing', 'vegetative').
  final String currentStage;

  const LifecycleTimeline({super.key, required this.currentStage});

  static const _stageLabels = {
    'sowing': 'Sowing',
    'germination': 'Germination',
    'vegetative': 'Vegetative',
    'flowering': 'Flowering',
    'harvest': 'Harvest',
  };

  static const _stageIcons = {
    'sowing': Icons.grass,
    'germination': Icons.eco,
    'vegetative': Icons.park,
    'flowering': Icons.local_florist,
    'harvest': Icons.agriculture,
  };

  @override
  Widget build(BuildContext context) {
    final stages = AppConstants.growthStages;
    final currentIndex = stages.indexOf(currentStage).clamp(0, stages.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingMd,
            bottom: AppTheme.spacingSm,
          ),
          child: Text(
            'Growth Stage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Connecting line before (except first)
                  if (index > 0)
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: index <= currentIndex
                            ? AppTheme.primaryGreen
                            : AppTheme.dividerGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  // Stage node
                  _StageNode(
                    label: _stageLabels[stage] ?? stage,
                    icon: _stageIcons[stage] ?? Icons.circle,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StageNode extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  const _StageNode({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  State<_StageNode> createState() => _StageNodeState();
}

class _StageNodeState extends State<_StageNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StageNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color iconColor;

    if (widget.isCompleted) {
      circleColor = AppTheme.primaryGreen;
      iconColor = Colors.white;
    } else if (widget.isCurrent) {
      circleColor = AppTheme.primaryGreen.withOpacity(0.15);
      iconColor = AppTheme.primaryGreen;
    } else {
      circleColor = AppTheme.dividerGray.withOpacity(0.4);
      iconColor = AppTheme.textHint;
    }

    Widget circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: widget.isCurrent
            ? Border.all(color: AppTheme.primaryGreen, width: 2.5)
            : null,
        boxShadow: widget.isCompleted
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(widget.icon, color: iconColor, size: 22),
    );

    if (widget.isCurrent) {
      circle = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: circle,
      );
    }

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 6),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  widget.isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: widget.isCompleted || widget.isCurrent
                  ? AppTheme.textPrimary
                  : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
