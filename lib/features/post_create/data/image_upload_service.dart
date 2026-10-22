import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Uploads post photos and returns their server URLs in the same order.
abstract class ImageUploadService {
  Future<List<String>> upload(List<XFile> images);
}

/// `POST /uploads/images` (multipart `files`, jpg/jpeg/png/webp, ≤10).
class DioImageUploadService implements ImageUploadService {
  DioImageUploadService(this._api);

  final ApiClient _api;

  @override
  Future<List<String>> upload(List<XFile> images) async {
    if (images.isEmpty) return const [];
    final form = FormData();
    for (final image in images) {
      final name = _fileName(image);
      form.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            image.path,
            filename: name,
            contentType: DioMediaType('image', _subtype(name)),
          ),
        ),
      );
    }
    final response = await _api.post<dynamic>('/uploads/images', data: form);
    final data = response.data;
    if (data is! List || data.length != images.length) {
      throw const ApiException(message: '사진 업로드 응답 형식이 올바르지 않습니다.');
    }
    return data.map((e) => e.toString()).toList();
  }

  /// Server validates by extension; picker files may lack one.
  static String _fileName(XFile image) {
    final raw = image.name.isNotEmpty ? image.name : image.path;
    final name = raw.split(RegExp(r'[/\\]')).last;
    final lower = name.toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    return allowed.any(lower.endsWith) ? name : '$name.jpg';
  }

  static String _subtype(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }
}

/// `USE_MOCK_API=true`: no server — stable placeholder images per slot.
class MockImageUploadService implements ImageUploadService {
  @override
  Future<List<String>> upload(List<XFile> images) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final seed = DateTime.now().millisecondsSinceEpoch;
    return [
      for (var i = 0; i < images.length; i++)
        'https://picsum.photos/seed/flatpost$seed-$i/800/600',
    ];
  }
}
