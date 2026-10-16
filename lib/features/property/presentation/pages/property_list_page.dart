import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/common_widgets/custom_app_bar.dart';
import '../../../../core/common_widgets/skeleton_card.dart';
import '../bloc/property_bloc.dart';
import '../widgets/property_card.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  bool _chromeVisible = true;

  void _handleUserScroll(UserScrollNotification notification) {
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _chromeVisible) {
      setState(() => _chromeVisible = false);
    } else if (direction == ScrollDirection.forward && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        locationName: '신촌동',
        visible: _chromeVisible,
        onLocationTap: () {},
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _handleUserScroll(notification);
          return false;
        },
        child: BlocBuilder<PropertyBloc, PropertyState>(
          builder: (context, state) {
            return switch (state) {
              PropertyInitial() || PropertyLoading() =>
                const SkeletonCardList(count: 4),
              PropertyFailure(:final message) => Center(child: Text(message)),
              PropertyLoaded(:final items) => RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<PropertyBloc>()
                        .add(const PropertyLoadRequested());
                    await context.read<PropertyBloc>().stream.firstWhere(
                          (s) => s is PropertyLoaded || s is PropertyFailure,
                        );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return PropertyCard(property: items[index]);
                    },
                  ),
                ),
            };
          },
        ),
      ),
    );
  }
}
