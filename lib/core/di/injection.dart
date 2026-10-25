import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/app_config.dart';
import '../../features/auth/data/repositories/dio_auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/block_report/data/dio_block_report_repository.dart';
import '../../features/block_report/data/mock_block_report_repository.dart';
import '../../features/block_report/domain/block_report_repository.dart';
import '../../features/chat/data/repositories/dio_chat_repository.dart';
import '../../features/chat/data/repositories/mock_chat_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/feed/data/repositories/dio_feed_repository.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/data/repositories/mock_feed_repository.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/location/data/datasources/location_service.dart';
import '../../features/location/data/repositories/dio_location_repository.dart';
import '../../features/location/data/repositories/mock_location_repository.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/notice/data/dio_notice_repository.dart';
import '../../features/notice/data/mock_notice_repository.dart';
import '../../features/notice/domain/notice_repository.dart';
import '../../features/post_create/data/image_upload_service.dart';
import '../auth/token_refresher.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<ApiClient>()) return;

  final config = AppConfig.resolve();
  sl.registerSingleton<AppConfig>(config);

  // 최근 검색어 (search history).
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final tokens = TokenStorage();
  await tokens.load();
  sl.registerSingleton<TokenStorage>(tokens);

  // Shared so REST and WebSocket refreshes collapse into one request.
  sl.registerLazySingleton<TokenRefresher>(
    () => TokenRefresher(tokens: sl(), baseUrl: config.apiBaseUrl),
  );
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokens: sl(), refresher: sl(), config: sl()),
  );
  sl.registerLazySingleton<LocationService>(LocationService.new);

  // Mock ↔ Real repository switch (UI/providers stay unchanged).
  if (config.useMockApi) {
    sl.registerLazySingleton<MockFeedRepository>(MockFeedRepository.new);
    sl.registerLazySingleton<FeedRepository>(
      () => FeedRepositoryImpl(sl<MockFeedRepository>()),
    );
    sl.registerLazySingleton<ChatRepository>(MockChatRepository.new);
    sl.registerLazySingleton<LocationRepository>(MockLocationRepository.new);
    sl.registerLazySingleton<AuthRepository>(MockAuthRepository.new);
    sl.registerLazySingleton<ImageUploadService>(MockImageUploadService.new);
    sl.registerLazySingleton<BlockReportRepository>(
      MockBlockReportRepository.new,
    );
    sl.registerLazySingleton<NoticeRepository>(MockNoticeRepository.new);
  } else {
    sl.registerLazySingleton<ImageUploadService>(
      () => DioImageUploadService(sl()),
    );
    sl.registerLazySingleton<FeedRepository>(
      () => DioFeedRepository(sl()),
    );
    sl.registerLazySingleton<ChatRepository>(
      () => DioChatRepository(sl(), sl(), sl()),
    );
    sl.registerLazySingleton<AuthRepository>(
      () => DioAuthRepository(sl()),
    );
    sl.registerLazySingleton<LocationRepository>(
      () => DioLocationRepository(sl()),
    );
    sl.registerLazySingleton<BlockReportRepository>(
      () => DioBlockReportRepository(sl()),
    );
    sl.registerLazySingleton<NoticeRepository>(
      () => DioNoticeRepository(sl()),
    );
  }
}
