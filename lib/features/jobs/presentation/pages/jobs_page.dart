import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/common_widgets/badge_chip.dart';
import '../../../../core/common_widgets/custom_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  static const _mocks = [
    (title: '카페 주말 오픈 알바', place: '화양동', pay: '시급 11,000원', urgent: true),
    (title: '편의점 야간 근무', place: '공덕동', pay: '시급 12,000원', urgent: true),
    (title: '짐 옮기기 심부름', place: '연남동', pay: '건당 3만', urgent: false),
    (title: '과외 전단지 배포', place: '신촌동', pay: '시급 10,000원', urgent: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        locationName: '신촌동',
        onLocationTap: () {},
      ),
      body: ListView.separated(
        itemCount: _mocks.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final job = _mocks[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            title: Text(job.title),
            subtitle: Text('${job.place} · ${job.pay}'),
            trailing: job.urgent
                ? const BadgeChip(label: '급구', type: BadgeType.urgent)
                : const BadgeChip(label: '모집중'),
            onTap: () => context.push('${RouteNames.home}/f-103-p1-2'),
          );
        },
      ),
    );
  }
}
