import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/app_config.dart';
import '../../data/local/local_storage.dart';
import '../../features/auth/data/repositories/dio_auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/chat/data/repositories/dio_chat_repository.dart';
import '../../features/chat/data/repositories/mock_chat_repository.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/feed/data/repositories/dio_feed_repository.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/data/repositories/mock_feed_repository.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_feed_page_usecase.dart';
import '../../features/local_life/data/datasources/local_life_remote_datasource.dart';
import '../../features/local_life/data/repositories/local_life_repository_impl.dart';
import '../../features/local_life/domain/repositories/local_life_repository.dart';
import '../../features/local_life/domain/usecases/get_local_posts_usecase.dart';
import '../../features/location/data/repositories/dio_location_repository.dart';
import '../../features/location/data/repositories/mock_location_repository.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/mypage/data/repositories/profile_repository_impl.dart';
import '../../features/mypage/domain/repositories/profile_repository.dart';
import '../../features/mypage/domain/usecases/get_my_profile_usecase.dart';
import '../../features/property/data/datasources/property_remote_datasource.dart';
import '../../features/property/data/repositories/property_repository_impl.dart';
import '../../features/property/domain/repositories/property_repository.dart';
import '../../features/property/domain/usecases/get_properties_usecase.dart';
import '../../features/property/presentation/bloc/property_bloc.dart';
import '../auth/token_refresher.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../utils/location_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<ApiClient>()) return;

  final config = AppConfig.resolve();
  sl.registerSingleton<AppConfig>(config);

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<LocalStorage>(() => LocalStorage(sl()));

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
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));
  sl.registerLazySingleton<LocationService>(LocationService.new);

  sl.registerLazySingleton<PropertyRemoteDataSource>(
    PropertyRemoteDataSourceStub.new,
  );
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(sl()),
  );
  sl.registerFactory(() => GetPropertiesUseCase(sl()));
  sl.registerFactory(
    () => PropertyBloc(sl())..add(const PropertyLoadRequested()),
  );

  // Mock ↔ Real repository switch (UI/providers stay unchanged).
  if (config.useMockApi) {
    sl.registerLazySingleton<MockFeedRepository>(MockFeedRepository.new);
    sl.registerLazySingleton<FeedRepository>(
      () => FeedRepositoryImpl(sl<MockFeedRepository>()),
    );
    sl.registerLazySingleton<ChatRepository>(MockChatRepository.new);
    sl.registerLazySingleton<LocationRepository>(MockLocationRepository.new);
    sl.registerLazySingleton<AuthRepository>(MockAuthRepository.new);
  } else {
    sl.registerLazySingleton<FeedRepository>(
      () => DioFeedRepository(sl()),
    );
    sl.registerLazySingleton<ChatRepository>(
      () => DioChatRepository(sl(), sl(), sl(), sl()),
    );
    sl.registerLazySingleton<AuthRepository>(
      () => DioAuthRepository(sl()),
    );
    sl.registerLazySingleton<LocationRepository>(
      () => DioLocationRepository(sl()),
    );
  }

  sl.registerFactory(() => GetFeedPageUseCase(sl()));

  sl.registerLazySingleton<LocalLifeRemoteDataSource>(
    LocalLifeRemoteDataSourceStub.new,
  );
  sl.registerLazySingleton<LocalLifeRepository>(
    () => LocalLifeRepositoryImpl(sl()),
  );
  sl.registerFactory(() => GetLocalPostsUseCase(sl()));

  sl.registerLazySingleton<ProfileRepository>(ProfileRepositoryStub.new);
  sl.registerFactory(() => GetMyProfileUseCase(sl()));
}
