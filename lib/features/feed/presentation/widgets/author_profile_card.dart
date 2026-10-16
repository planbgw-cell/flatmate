import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/feed_item.dart';

class AuthorProfileCard extends StatelessWidget {
  const AuthorProfileCard({super.key, required this.item});

  final FeedItem item;

  Color get _scoreColor {
    if (item.trustScore >= 42) return AppColors.statusSuccess;
    if (item.trustScore >= 36) return AppColors.statusWarning;
    return AppColors.statusUrgent;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (item.trustScore / 50.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: item.authorAvatarUrl != null
                ? CachedNetworkImageProvider(item.authorAvatarUrl!)
                : null,
            child: item.authorAvatarUrl == null
                ? Text(
                    item.authorName.characters.first,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.authorName, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${item.neighborhood} 인증 ${item.verificationCount}회',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thermostat, size: 16, color: _scoreColor),
                  const SizedBox(width: 2),
                  Text(
                    '${item.trustScore.toStringAsFixed(1)}°C',
                    style: AppTypography.titleMedium.copyWith(
                      color: _scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    color: _scoreColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.trustPercentLabel,
                style: AppTypography.caption.copyWith(color: _scoreColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
