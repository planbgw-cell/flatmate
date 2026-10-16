import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('게스트'),
                subtitle: const Text('guest@flatmate.app'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: '로그인',
              onPressed: () => context.go(RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}
