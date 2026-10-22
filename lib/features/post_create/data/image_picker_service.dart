import 'package:image_picker/image_picker.dart';

/// Camera / gallery picks, downscaled to keep uploads well under the 10MB
/// per-file server limit.
class PostImagePicker {
  PostImagePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  static const _maxDimension = 1920.0;
  static const _quality = 85;

  final ImagePicker _picker;

  /// Up to [limit] photos from the gallery (`[]` when cancelled).
  Future<List<XFile>> pickFromGallery({required int limit}) async {
    if (limit <= 0) return const [];
    if (limit == 1) {
      final single = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
      return single == null ? const [] : [single];
    }
    final picked = await _picker.pickMultiImage(
      limit: limit,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    // Some pickers ignore `limit`; enforce it here.
    return picked.take(limit).toList();
  }

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
  }
}
