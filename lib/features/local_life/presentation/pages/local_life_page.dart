import 'package:flutter/material.dart';

import '../../../../core/common_widgets/custom_app_bar.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/usecases/get_local_posts_usecase.dart';
import '../widgets/local_post_tile.dart';

class LocalLifePage extends StatelessWidget {
  const LocalLifePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        locationName: '신촌동',
        onLocationTap: () {},
      ),
      body: FutureBuilder(
        future: sl<GetLocalPostsUseCase>()(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('아직 게시글이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => LocalPostTile(post: posts[index]),
          );
        },
      ),
    );
  }
}
