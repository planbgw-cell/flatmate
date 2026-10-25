import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/models/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../screens/feed_detail_screen.dart';

/// Id-based entry (`/feed/detail/:id`, `/share/feed/:id`) — loads then shows
/// [FeedDetailScreen].
class FeedDetailPage extends StatefulWidget {
  const FeedDetailPage({super.key, required this.feedId});

  final String feedId;

  @override
  State<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> {
  late final Future<FeedItem?> _future =
      sl<FeedRepository>().fetchById(widget.feedId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FeedItem?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('상세')),
            body: Center(
              child: Text('게시글을 찾을 수 없습니다. (${widget.feedId})'),
            ),
          );
        }
        return FeedDetailScreen(item: item);
      },
    );
  }
}
