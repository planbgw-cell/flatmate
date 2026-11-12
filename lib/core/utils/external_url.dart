import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] outside the app (browser); `false` if nothing could handle it.
typedef ExternalUrlLauncher = Future<bool> Function(Uri url);

/// Overridden in tests to record launched URLs.
final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return (url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  };
});
