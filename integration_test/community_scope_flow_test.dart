// On-device E2E (guest, 야탑1동 = server dong 15): 동네소식 [우리 동네]
// (public_scope=sigungu, default) → [우리 권역 축제] (public_scope=zone):
// lists match the server, 권역 cards show "[수도권 축제] 경기 가평군" badges.
//
//   adb install -r -g build\app\outputs\flutter-apk\app-debug.apk
//   flutter test integration_test/community_scope_flow_test.dart \
//     -d <device-id> --dart-define=USE_MOCK_API=false
import 'package:dio/dio.dart';
import 'package:flatmate_app/app/app.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/di/injection.dart';
import 'package:flatmate_app/features/community/presentation/providers/community_feed_provider.dart';
import 'package:flatmate_app/features/community/presentation/screens/community_screen.dart';
import 'package:flatmate_app/features/feed/domain/models/region.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/screens/feed_screen.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flatmate_app/features/location/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final _log = <String>[];

void _step(String message) {
  _log.add(message);
  debugPrint('[E2E] $message');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      await _pumpFor(tester, const Duration(milliseconds: 800));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition,
  String what,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for $what');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실기기 E2E: 동네소식 [우리 동네] / [우리 권역 축제] 칩', (tester) async {
    await configureDependencies();
    expect(sl<AppConfig>().useMockApi, isFalse,
        reason: 'Run with --dart-define=USE_MOCK_API=false');
    await sl<TokenStorage>().clear();

    final dio = Dio(BaseOptions(baseUrl: AppConfig.devServerBaseUrl));
    Future<List<Map<String, dynamic>>> server(String scope) async {
      final response = await dio.get<Map<String, dynamic>>(
        '/feeds',
        queryParameters: {
          'feed_type': 'LOCAL_NEWS',
          'location_id': 15,
          'public_scope': scope,
          'page': 1,
          'limit': 20,
        },
      );
      return [
        for (final row in response.data!['items'] as List)
          Map<String, dynamic>.from(row as Map),
      ];
    }

    await tester.pumpWidget(ProviderScope(child: FlatmateApp()));
    await _pumpUntil(tester, find.text('로그인 없이 둘러보기'));
    await _tap(tester, find.text('로그인 없이 둘러보기'));
    await _pumpUntil(tester, find.byType(FeedScreen));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(FeedScreen)));
    container.read(currentLocationProvider.notifier).state = const LocationItem(
      id: '15',
      cityName: '경기도',
      districtName: '성남시 분당구',
      dongName: '야탑1동',
      latitude: 37.41205313694714,
      longitude: 127.13027133504737,
    );

    List<String>? appIds() => container
        .read(communityFeedProvider)
        .value
        ?.items
        .map((e) => e.id)
        .toList();

    // 1) [우리 동네] (default) = public_scope=sigungu.
    await _tap(tester, find.byKey(const ValueKey('tab-community')));
    await _pumpUntil(tester, find.byType(CommunityScreen));
    expect(container.read(communityScopeProvider), PublicScope.sigungu);
    final sigungu = await server('sigungu');
    await _pumpUntilTrue(
      tester,
      () => appIds()?.join(',') == sigungu.map((e) => '${e['id']}').join(','),
      '우리 동네 list',
    );
    if (sigungu.isEmpty) {
      expect(find.byKey(const ValueKey('community-empty')), findsOneWidget);
    }
    _step('[우리 동네] 기본 선택 · 서버 location_id=15&public_scope=sigungu '
        '${sigungu.length}건과 일치');

    // 2) [우리 권역 축제] = public_scope=zone.
    await _tap(tester, find.byKey(const ValueKey('community-scope-zone')));
    final zone = await server('zone');
    expect(zone, isNotEmpty, reason: '수도권 축제 on the server');
    await _pumpUntilTrue(
      tester,
      () => appIds()?.join(',') == zone.map((e) => '${e['id']}').join(','),
      '권역 list',
    );
    expect(
      find.text('수도권(서울·인천·경기) 축제를 모아 보여드려요'),
      findsOneWidget,
    );
    for (final row in zone) {
      expect(zoneOfAddress(row['address'] as String?), '수도권',
          reason: '${row['address']}');
    }
    final first = zone.first;
    final region = find.byKey(ValueKey('festival-region-${first['id']}'));
    await _pumpUntil(tester, region);
    expect(
      find.descendant(of: region, matching: find.text('수도권 축제')),
      findsOneWidget,
    );
    final label = regionLabel(first['address'] as String?);
    expect(find.descendant(of: region, matching: find.text(label)), findsOneWidget);
    _step('[우리 권역 축제] → 서버 public_scope=zone 첫 페이지 ${zone.length}건과 '
        '같은 순서 · 모두 수도권 · 첫 카드 "[수도권 축제] $label"');

    // 3) Back to [우리 동네].
    await _tap(tester, find.byKey(const ValueKey('community-scope-sigungu')));
    await _pumpUntilTrue(
      tester,
      () => appIds()?.join(',') == sigungu.map((e) => '${e['id']}').join(','),
      '우리 동네 again',
    );
    expect(find.byKey(ValueKey('festival-region-${first['id']}')), findsNothing);
    _step('[우리 동네]로 복귀');

    debugPrint('[E2E] ===== SUMMARY =====\n${_log.join('\n')}');
  });
}
