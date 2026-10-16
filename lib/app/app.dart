import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';

class FlatmateApp extends StatelessWidget {
  FlatmateApp({super.key, GoRouter? router})
      : _router = router ?? createAppRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
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
