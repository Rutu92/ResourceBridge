import 'package:flutter/material.dart';
import '../models/resource_model.dart';
import '../utils/constants.dart';
import 'dart:convert';

class ItemCard extends StatelessWidget {
  final ResourceModel item;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.trailing,
  });

  Color get _classificationColor {
    switch (item.aiClassification) {
      case AppConstants.classUsable:
        return AppColors.secondary;
      case AppConstants.classRepairable:
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  Color get _statusColor {
    switch (item.status) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusClassified:
        return AppColors.primary;
      case AppConstants.statusMatched:
        return AppColors.secondary;
      case AppConstants.statusInRepair:
        return AppColors.warning;
      case AppConstants.statusCompleted:
        return AppColors.statusCompleted;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case AppConstants.statusPending:
        return 'PENDING';
      case AppConstants.statusClassified:
        return 'CLASSIFIED';
      case AppConstants.statusMatched:
        return 'NGO MATCHED';
      case AppConstants.statusPickupScheduled:
        return 'PICKUP SCHEDULED';
      case AppConstants.statusInRepair:
        return 'IN REPAIR';
      case AppConstants.statusRepaired:
        return 'REPAIRED';
      case AppConstants.statusDelivered:
        return 'DELIVERED';
      case AppConstants.statusCompleted:
        return 'COMPLETED';
      default:
        return item.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: item.imageUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(item.imageUrl.split(',')[1]),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textMuted, size: 40),
                          ),
                        ),
                      )
                    : Image.network(
                        item.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: AppColors.textMuted, size: 40),
                          ),
                        ),
                      ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName.isNotEmpty
                              ? item.itemName
                              : item.materialType,
                          style: AppTextStyles.headingMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: _statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          _statusLabel,
                          style: AppTextStyles.label.copyWith(
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Classification badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _classificationColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          item.aiClassification.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: _classificationColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.repairType != 'none' && item.repairType.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '🔧 ${item.repairType.toUpperCase()}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // Footer row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.rewardPoints > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '+${item.rewardPoints} pts',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (trailing != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}