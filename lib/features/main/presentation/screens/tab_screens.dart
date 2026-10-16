import 'package:flutter/material.dart';

import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../mypage/presentation/pages/my_page.dart';
import '../../../property/presentation/pages/property_list_page.dart';

export '../../../feed/presentation/screens/feed_screen.dart' show FeedScreen;

/// Tab 1 — 부동산/주거
class RealEstateScreen extends StatelessWidget {
  const RealEstateScreen({super.key});

  @override
  Widget build(BuildContext context) => const PropertyListPage();
}

/// Tab 2 — 구인구직
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) => const JobsPage();
}

/// Tab 3 — 채팅
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) => const ChatListScreen();
}

/// Tab 4 — 내 정보
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) => const MyPage();
}
