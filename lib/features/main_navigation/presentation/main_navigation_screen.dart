import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../core/common_widgets/custom_bottom_navigation_bar.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/write_compose_sheet.dart';

/// Main shell: 홈 · 동네소식 · 내주변 · 채팅 · 마이플랫, each tab preserved via
/// [StatefulNavigationShell] (IndexedStack). Scroll-triggered 글쓰기 FAB.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const homeIndex = 0;
  static const communityIndex = 1;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _fabVisible = true;

  int get _index => widget.navigationShell.currentIndex;

  /// 내주변 (map + cards), 채팅 and 마이플랫 have no 글쓰기.
  bool get _showFab =>
      _index == MainNavigationScreen.homeIndex ||
      _index == MainNavigationScreen.communityIndex;

  void _onTabTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (!_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
    return false;
  }

  Future<void> _onWritePressed() async {
    if (_index == MainNavigationScreen.communityIndex) {
      context.push(RouteNames.postCreateCommunity);
      return;
    }
    final action = await showWriteComposeSheet(context);
    if (!mounted || action == null) return;

    final path = switch (action) {
      WriteComposeAction.property => RouteNames.postCreateRealEstate,
      WriteComposeAction.job => RouteNames.postCreateJob,
      WriteComposeAction.post => RouteNames.postCreateGeneral,
      WriteComposeAction.community => RouteNames.postCreateCommunity,
    };
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final showFab = _showFab;
    final fabExpanded = _fabVisible;

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.navigationShell,
      ),
      floatingActionButton: showFab
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: fabExpanded ? Offset.zero : const Offset(0, 1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: fabExpanded ? 1 : 0,
                child: FloatingActionButton.extended(
                  key: const ValueKey('write-fab'),
                  onPressed: fabExpanded ? _onWritePressed : null,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('글쓰기'),
                ),
              ),
            )
          : null,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
