import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class FlatmateApp extends ConsumerWidget {
  FlatmateApp({super.key, GoRouter? router})
      : _router = router ?? createAppRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // App-wide session: restores the user (→ 대표 동네 binding) on start and
    // mirrors dong changes to the server.
    ref.listen(authProvider, (_, _) {});
    ref.listen(primaryLocationSyncProvider, (_, _) {});

    return AppBlocProviders(
      child: MaterialApp.router(
        title: 'Flatmate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
