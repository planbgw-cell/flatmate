import '../../app/config/app_config.dart';

/// Server media is returned as origin-relative paths (`/static/images/…`);
/// they live next to the API, outside the `/api/v1` prefix.
String resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final base = Uri.parse(apiBaseUrl ?? AppConfig.resolve().apiBaseUrl);
  return base.replace(path: value, query: null, fragment: null).toString();
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
