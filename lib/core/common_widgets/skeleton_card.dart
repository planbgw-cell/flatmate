import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  color: AppColors.border,
                ),
                const SizedBox(height: 8),
                Container(height: 12, width: 120, color: AppColors.border),
                const SizedBox(height: 12),
                Container(height: 16, width: 80, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, _) => const SkeletonCard(),
    );
  }
}
