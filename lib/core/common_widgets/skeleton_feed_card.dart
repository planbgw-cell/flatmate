import 'package:flutter/material.dart';

import 'skeleton_card.dart';

/// Backward-compatible aliases for [SkeletonCard].
class SkeletonFeedCard extends StatelessWidget {
  const SkeletonFeedCard({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonCard();
}

class SkeletonFeedList extends StatelessWidget {
  const SkeletonFeedList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) => SkeletonCardList(count: count);
}
