import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../core/common_widgets/custom_bottom_navigation_bar.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/write_compose_sheet.dart';

/// Main shell: preserves each tab via [StatefulNavigationShell] (IndexedStack).
/// Scroll-triggered FAB + write compose bottom sheet.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _fabVisible = true;

  bool get _showFab {
    // Hide on My Page tab
    return widget.navigationShell.currentIndex != 4;
  }

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
    final action = await showWriteComposeSheet(context);
    if (!mounted || action == null) return;

    final path = switch (action) {
      WriteComposeAction.property => RouteNames.postCreateRealEstate,
      WriteComposeAction.job => RouteNames.postCreateJob,
      WriteComposeAction.post => RouteNames.postCreateGeneral,
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
