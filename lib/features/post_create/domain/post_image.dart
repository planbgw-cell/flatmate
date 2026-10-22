import 'package:image_picker/image_picker.dart';

import '../../feed/domain/models/feed_item.dart';

/// A photo in the post form: already on the server (edit mode) or newly
/// picked on the device (uploaded on submit).
sealed class PostImage {
  const PostImage();
}

class RemotePostImage extends PostImage {
  const RemotePostImage(this.url);

  /// Absolute display URL (see `resolveMediaUrl`).
  final String url;
}

class LocalPostImage extends PostImage {
  const LocalPostImage(this.file);

  final XFile file;
}

/// The post's server photos in order (falls back to the lone thumbnail).
List<PostImage> remotePostImages(FeedItem item) {
  final urls = item.imageUrls.isNotEmpty
      ? item.imageUrls
      : [if (item.thumbnailUrl.isNotEmpty) item.thumbnailUrl];
  return [for (final url in urls) RemotePostImage(url)];
}
