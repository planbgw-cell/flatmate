import '../../app/config/app_config.dart';

/// Display URL for server media:
/// - origin-relative paths (`/static/images/…`, uploads) live next to the API,
///   outside the `/api/v1` prefix;
/// - external absolute URLs (e.g. 한국관광공사 `tong.visitkorea.or.kr`) are
///   used as-is, but `http` is upgraded to `https` because Android blocks
///   cleartext traffic to every host except the dev API server.
String resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return '';
  final base = Uri.parse(apiBaseUrl ?? AppConfig.resolve().apiBaseUrl);
  if (value.startsWith('//')) return 'https:$value';
  if (value.startsWith('https://')) return value;
  if (value.startsWith('http://')) {
    final uri = Uri.tryParse(value);
    final isApiHost =
        uri != null && uri.host == base.host && uri.port == base.port;
    return isApiHost ? value : 'https://${value.substring('http://'.length)}';
  }
  final path = value.startsWith('/') ? value : '/$value';
  return base.replace(path: path, query: null, fragment: null).toString();
}

/// Inverse of [resolveMediaUrl] for request bodies: URLs on the API origin go
/// back to `/static/…` paths; external URLs are kept as-is.
String toServerMediaPath(String url, {String? apiBaseUrl}) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return url;
  final base = Uri.parse(apiBaseUrl ?? AppConfig.resolve().apiBaseUrl);
  final sameOrigin = uri.scheme == base.scheme &&
      uri.host == base.host &&
      uri.port == base.port;
  return sameOrigin ? uri.path : url;
}
