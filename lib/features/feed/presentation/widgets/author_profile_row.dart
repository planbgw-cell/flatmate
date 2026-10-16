import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'trust_score_badge.dart';

class AuthorProfileRow extends StatelessWidget {
  const AuthorProfileRow({
    super.key,
    required this.name,
    required this.neighborhood,
    required this.trustScore,
    this.avatarUrl,
  });

  final String name;
  final String neighborhood;
  final double trustScore;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: avatarUrl != null
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    name.characters.first,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  neighborhood,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TrustScoreBadge(score: trustScore),
        ],
      ),
    );
  }
}

