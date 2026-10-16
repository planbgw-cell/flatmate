import 'package:flutter/material.dart';

import 'badge_chip.dart';

enum StatusChipVariant { bump, urgent, status, neutral }

/// Backward-compatible wrapper around [BadgeChip].
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.neutral,
  });

  final String label;
  final StatusChipVariant variant;

  BadgeType get _type => switch (variant) {
        StatusChipVariant.bump => BadgeType.success,
        StatusChipVariant.urgent => BadgeType.urgent,
        StatusChipVariant.status => BadgeType.warning,
        StatusChipVariant.neutral => BadgeType.normal,
      };

  @override
  Widget build(BuildContext context) {
    return BadgeChip(label: label, type: _type);
  }
}
