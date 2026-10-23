import 'package:flatmate_app/core/network/api_exception.dart';
import 'package:flatmate_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flatmate_app/features/block_report/data/mock_block_report_repository.dart';
import 'package:flatmate_app/features/block_report/domain/models/report_reason.dart';
import 'package:flatmate_app/features/block_report/presentation/providers/blocked_users_provider.dart';
import 'package:flatmate_app/features/block_report/presentation/screens/blocked_users_screen.dart';
import 'package:flatmate_app/features/block_report/presentation/widgets/report_sheet.dart';
import 'package:flatmate_app/features/feed/data/repositories/mock_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
import 'package:flatmate_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

FeedItem _item(String id, String authorId) => FeedItem(
      id: id,
      title: '글 $id',
      neighborhood: '정자동',
      postedAt: DateTime(2026, 10, 23),
      priceOrCondition: '15,000원',
      thumbnailUrl: '',
      likeCount: 0,
      chatCount: 0,
      category: FeedCategory.market,
      badges: const [],
      isBumped: false,
      authorId: authorId,
      authorName: '이웃 $authorId',
    );

/// Server stand-in that does not filter blocked authors itself.
class _Feeds extends MockFeedRepository {
  int fetches = 0;

  @override
  Future<List<FeedItem>> fetchFeeds({
    required int page,
    int pageSize = 10,
    String category = 'all',
    LocationItem? location,
    double radiusKm = 3,
    FeedSort sort = FeedSort.latest,
  }) async {
    fetches++;
    return [_item('1', '21'), _item('2', '22'), _item('3', '21')];
  }
}

class _FailingUnblock extends MockBlockReportRepository {
  @override
  Future<void> unblockUser(String userId) async {
    throw const ApiException(message: '네트워크 연결을 확인해 주세요.');
  }
}

List<Override> _overrides(MockBlockReportRepository blocks, _Feeds feeds) => [
      blockReportRepositoryProvider.overrideWithValue(blocks),
      feedRepositoryProvider.overrideWithValue(feeds),
      currentUserIdProvider.overrideWithValue('7'),
    ];

void main() {
  testWidgets('report sheet: submit needs a reason, returns reason + details',
      (tester) async {
    ReportSubmission? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showReportSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton submit() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('report-submit')));
    expect(submit().onPressed, isNull);
    expect(find.text('사기 의심'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report-reason-FRAUD')));
    await tester.enterText(
      find.byKey(const ValueKey('report-details')),
      ' 선입금을 요구해요 ',
    );
    await tester.pump();
    expect(submit().onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pumpAndSettle();

    expect(result?.reason, ReportReason.fraud);
    expect(result?.details, '선입금을 요구해요');
  });

  test('block hides the author from the feed; unblock brings posts back',
      () async {
    final feeds = _Feeds();
    final container = ProviderContainer(
      overrides: _overrides(MockBlockReportRepository(), feeds),
    );
    addTearDown(container.dispose);

    var list = await container.read(feedListProvider.future);
    expect(list.items.map((e) => e.id), ['1', '2', '3']);

    final blocked = await container
        .read(blockedUsersProvider.notifier)
        .block(list.items.first);
    expect(blocked.userId, '21');
    expect(
      container.read(feedListProvider).value?.items.map((e) => e.id),
      ['2'],
      reason: 'removed before the refetch',
    );
    list = await container.read(feedListProvider.future);
    expect(list.items.map((e) => e.id), ['2']);
    expect(container.read(blockedUserIdsProvider), {'21'});
    expect(container.read(feedMutationTickProvider), 1);

    await container.read(blockedUsersProvider.notifier).unblock('21');
    list = await container.read(feedListProvider.future);
    expect(list.items.map((e) => e.id), ['1', '2', '3']);
    expect(container.read(blockedUserIdsProvider), isEmpty);
    expect(feeds.fetches, 3);
  });

  testWidgets('blocked users screen: unblock removes the tile',
      (tester) async {
    final blocks = MockBlockReportRepository();
    await blocks.blockUser('21');
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(blocks, _Feeds()),
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('차단 사용자 관리'), findsOneWidget);
    expect(find.byKey(const ValueKey('blocked-user-21')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unblock-21')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blocked-user-21')), findsNothing);
    expect(find.text('차단한 사용자가 없어요.'), findsOneWidget);
    expect(find.text('이웃 21님의 차단을 해제했어요.'), findsOneWidget);
    expect(await blocks.getBlockedUsers(), isEmpty);
  });

  testWidgets('blocked users screen: failed unblock restores the tile',
      (tester) async {
    final blocks = _FailingUnblock();
    await blocks.blockUser('21');
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(blocks, _Feeds()),
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('unblock-21')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blocked-user-21')), findsOneWidget);
    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
  });

  test('mock repository rejects a duplicate report with 400', () async {
    final repo = MockBlockReportRepository();
    await repo.reportFeed('5', ReportReason.spam);
    await expectLater(
      repo.reportFeed('5', ReportReason.spam),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });
}
