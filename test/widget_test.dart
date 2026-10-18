import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/routes/app_router.dart';
import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/di/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('피드 필터·카드·새로고침 UI가 렌더링된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: FlatmateApp(
          router: createAppRouter(initialLocation: RouteNames.home),
        ),
      ),
    );
    await tester.pump();
    // Mock repo delay 300–500ms + frame
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('부동산/주거'), findsOneWidget);
    expect(find.text('단기 알바'), findsOneWidget);
    expect(find.text('중고/나눔'), findsOneWidget);
    expect(find.text('동네 소식'), findsOneWidget);

    expect(find.textContaining('신촌 풀옵션 원룸'), findsOneWidget);
    expect(find.textContaining('보증금 500'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.tap(find.text('단기 알바'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('시급'), findsWidgets);
    expect(find.textContaining('신촌 풀옵션 원룸'), findsNothing);
  });
}
