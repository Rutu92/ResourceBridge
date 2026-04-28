import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatusTracker extends StatelessWidget {
  final String currentStatus;
  final bool isRepairFlow;

  const StatusTracker({
    super.key,
    required this.currentStatus,
    this.isRepairFlow = false,
  });

  List<_TrackingStep> get _steps {
    if (isRepairFlow) {
      return [
        _TrackingStep(
          status: AppConstants.statusPending,
          label: 'Uploaded',
          icon: Icons.upload_outlined,
        ),
        _TrackingStep(
          status: AppConstants.statusClassified,
          label: 'Classified',
          icon: Icons.psychology_outlined,
        ),
        _TrackingStep(
          status: AppConstants.statusMatched,
          label: 'NGO Accepted',
          icon: Icons.handshake_outlined,
        ),
        _TrackingStep(
          status: AppConstants.statusInRepair,
          label: 'In Repair',
          icon: Icons.build_outlined,
        ),
        _TrackingStep(
          status: AppConstants.statusRepaired,
          label: 'Repaired',
          icon: Icons.check_circle_outline,
        ),
        _TrackingStep(
          status: AppConstants.statusCompleted,
          label: 'Delivered',
          icon: Icons.volunteer_activism_outlined,
        ),
      ];
    }

    return [
      _TrackingStep(
        status: AppConstants.statusPending,
        label: 'Uploaded',
        icon: Icons.upload_outlined,
      ),
      _TrackingStep(
        status: AppConstants.statusClassified,
        label: 'Classified',
        icon: Icons.psychology_outlined,
      ),
      _TrackingStep(
        status: AppConstants.statusMatched,
        label: 'NGO Matched',
        icon: Icons.handshake_outlined,
      ),
      _TrackingStep(
        status: AppConstants.statusPickupScheduled,
        label: 'Pickup Set',
        icon: Icons.local_shipping_outlined,
      ),
      _TrackingStep(
        status: AppConstants.statusCompleted,
        label: 'Delivered',
        icon: Icons.volunteer_activism_outlined,
      ),
    ];
  }

  int _getStepIndex(String status) {
    final steps = _steps;
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].status == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final currentIndex = _getStepIndex(currentStatus);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRACKING', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.secondary
                        : AppColors.border,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;
              final step = steps[stepIndex];

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.secondary
                          : isCurrent
                              ? AppColors.primary
                              : AppColors.surface,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.secondary
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.border,
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      size: 16,
                      color: isCompleted
                          ? AppColors.background
                          : isCurrent
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: 48,
                    child: Text(
                      step.label,
                      style: AppTextStyles.caption.copyWith(
                        color: isCompleted || isCurrent
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep {
  final String status;
  final String label;
  final IconData icon;

  _TrackingStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}