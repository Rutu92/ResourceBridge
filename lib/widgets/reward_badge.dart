import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RewardBadge extends StatelessWidget {
  final int points;
  final bool showTier;
  final bool compact;

  const RewardBadge({
    super.key,
    required this.points,
    this.showTier = true,
    this.compact = false,
  });

  String get _tier {
    if (points >= 1000) return 'Platinum';
    if (points >= 500) return 'Gold';
    if (points >= 200) return 'Silver';
    if (points >= 50) return 'Bronze';
    return 'Newcomer';
  }

  Color get _tierColor {
    if (points >= 1000) return const Color(0xFFE5E4E2);
    if (points >= 500) return AppColors.admin;
    if (points >= 200) return const Color(0xFFC0C0C0);
    if (points >= 50) return const Color(0xFFCD7F32);
    return AppColors.textMuted;
  }

  String get _tierEmoji {
    if (points >= 1000) return '💎';
    if (points >= 500) return '🥇';
    if (points >= 200) return '🥈';
    if (points >= 50) return '🥉';
    return '🌱';
  }

  int get _nextTierPoints {
    if (points >= 1000) return 1000;
    if (points >= 500) return 1000;
    if (points >= 200) return 500;
    if (points >= 50) return 200;
    return 50;
  }

  double get _progress {
    if (points >= 1000) return 1.0;
    int prev = 0;
    if (points >= 500) prev = 500;
    else if (points >= 200) prev = 200;
    else if (points >= 50) prev = 50;
    return (points - prev) / (_nextTierPoints - prev);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tierEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$points pts',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _tierColor.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            _tierColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_tierEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTier)
                    Text(
                      _tier,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: _tierColor,
                      ),
                    ),
                  Text(
                    '$points Points',
                    style: AppTextStyles.displayMedium,
                  ),
                ],
              ),
            ],
          ),
          if (points < 1000) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next tier',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '$_nextTierPoints pts',
                  style: AppTextStyles.caption.copyWith(
                    color: _tierColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}