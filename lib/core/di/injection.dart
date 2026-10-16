import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/local_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/data/repositories/mock_feed_repository.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_feed_page_usecase.dart';
import '../../features/local_life/data/datasources/local_life_remote_datasource.dart';
import '../../features/local_life/data/repositories/local_life_repository_impl.dart';
import '../../features/local_life/domain/repositories/local_life_repository.dart';
import '../../features/local_life/domain/usecases/get_local_posts_usecase.dart';
import '../../features/mypage/data/repositories/profile_repository_impl.dart';
import '../../features/mypage/domain/repositories/profile_repository.dart';
import '../../features/mypage/domain/usecases/get_my_profile_usecase.dart';
import '../../features/property/data/datasources/property_remote_datasource.dart';
import '../../features/property/data/repositories/property_repository_impl.dart';
import '../../features/property/domain/repositories/property_repository.dart';
import '../../features/property/domain/usecases/get_properties_usecase.dart';
import '../../features/property/presentation/bloc/property_bloc.dart';
import '../network/dio_client.dart';
import '../utils/location_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<DioClient>()) return;

  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<LocalStorage>(() => LocalStorage(sl()));
  sl.registerLazySingleton<DioClient>(DioClient.new);
  sl.registerLazySingleton<LocationService>(LocationService.new);

  sl.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSourceStub.new);
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => AuthBloc(sl()));

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

  sl.registerLazySingleton<MockFeedRepository>(MockFeedRepository.new);
  sl.registerLazySingleton<FeedRepository>(
    () => FeedRepositoryImpl(sl<MockFeedRepository>()),
  );
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
