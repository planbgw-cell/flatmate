import 'package:flatmate_app/app/routes/route_names.dart';
import 'package:flatmate_app/core/theme/app_colors.dart';
import 'package:flatmate_app/features/chat/domain/models/chat_room.dart';
import 'package:flatmate_app/features/chat/presentation/widgets/chat_product_header.dart';
import 'package:flatmate_app/features/chat/presentation/widgets/chat_room_tile.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/mypage/presentation/widgets/my_feed_tile.dart';
import 'package:flatmate_app/features/post_create/presentation/widgets/post_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FeedItem _feed({
  TradeStatus status = TradeStatus.selling,
  String id = '1',
}) =>
    FeedItem(
      id: id,
      title: '테스트 글',
      neighborhood: '정자동',
      postedAt: DateTime(2026, 11, 1),
      priceOrCondition: '월 50만',
      thumbnailUrl: '',
      likeCount: 0,
      chatCount: 0,
      category: FeedCategory.housing,
      badges: const [],
      isBumped: false,
      tradeStatus: status,
    );

ChatRoom _room({String feedId = 'feed-9'}) => ChatRoom(
      id: 'r1',
      feedItemId: feedId,
      feedTitle: '원글 제목',
      feedPrice: '월 50만',
      feedThumbnail: '',
      opponentName: '이웃',
      lastMessage: '안녕하세요',
      lastMessageTime: DateTime(2026, 11, 1),
      unreadCount: 2,
    );

void main() {
  testWidgets('관심목록 타일: COMPLETED면 마감됨 배지', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyFeedTile(
            item: _feed(status: TradeStatus.completed),
            asCard: true,
            showClosedBadge: true,
            onTap: () {},
            trailing: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('마감됨'), findsOneWidget);
    expect(find.text('거래완료'), findsNothing);
    expect(find.byKey(const ValueKey('closed-badge')), findsOneWidget);
  });

  testWidgets('관심목록 빈 상태: 안내 문구와 홈으로 버튼', (tester) async {
    final router = GoRouter(
      initialLocation: '/favorites-empty',
      routes: [
        GoRoute(
          path: '/favorites-empty',
          builder: (_, _) => Scaffold(
            body: ListView(
              children: [
                const Icon(Icons.favorite_border_rounded),
                const Text('홈에서 관심 있는 방이나 동네 소식을 담아보세요'),
                FilledButton(
                  key: const ValueKey('favorites-go-home'),
                  onPressed: () {},
                  child: const Text('홈으로'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(
      find.text('홈에서 관심 있는 방이나 동네 소식을 담아보세요'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('favorites-go-home')), findsOneWidget);
  });

  testWidgets('채팅 헤더 탭 시 onTap 호출', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatProductHeader(
            room: _room(),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chat-product-header')));
    expect(tapped, isTrue);
  });

  testWidgets('안 읽음 배지는 accent 톤', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatRoomTile(room: _room(), onTap: () {}),
        ),
      ),
    );

    final badge = tester.widget<Container>(
      find.byKey(const ValueKey('room-unread-r1')),
    );
    final decoration = badge.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.accent);
  });

  testWidgets('글쓰기 폼 focusedBorder는 primary', (tester) async {
    final title = TextEditingController();
    final body = TextEditingController();
    addTearDown(title.dispose);
    addTearDown(body.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostFormFields(
            titleController: title,
            bodyController: body,
            showPrice: false,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byKey(const ValueKey('post-title')));
    final focused = field.decoration!.focusedBorder! as OutlineInputBorder;
    final enabled = field.decoration!.enabledBorder! as OutlineInputBorder;
    expect(focused.borderSide.color, AppColors.primary);
    expect(enabled.borderSide.color, AppColors.border);
  });

  testWidgets('SelectableChipRow 선택 시 primary 배경', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectableChipRow(
            options: const ['월세', '전세'],
            selected: const {'월세'},
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final chip = tester.widget<FilterChip>(find.byType(FilterChip).first);
    expect(chip.selectedColor, AppColors.primary);
    expect(chip.checkmarkColor, Colors.white);
  });
}
