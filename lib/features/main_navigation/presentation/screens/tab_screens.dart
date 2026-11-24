import 'package:flutter/material.dart';

import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../map_around/presentation/screens/map_around_screen.dart';
import '../../../mypage/presentation/pages/favorites_screen.dart';
import '../../../mypage/presentation/pages/my_page.dart';

/// Tab 0 — 홈 (통합 피드; 주거·알바는 상단 카테고리 칩)
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) => const FeedScreen();
}

/// Tab 1 — 동네지도
class MapAroundTab extends StatelessWidget {
  const MapAroundTab({super.key});

  @override
  Widget build(BuildContext context) => const MapAroundScreen();
}

/// Tab 2 — 관심목록
class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) => const FavoritesScreen();
}

/// Tab 3 — 채팅
class ChatListTab extends StatelessWidget {
  const ChatListTab({super.key});

  @override
  Widget build(BuildContext context) => const ChatListScreen();
}

/// Tab 4 — 마이플랫
class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key});

  @override
  Widget build(BuildContext context) => const MyPage();
}
