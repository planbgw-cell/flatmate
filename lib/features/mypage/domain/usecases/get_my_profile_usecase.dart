import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetMyProfileUseCase {
  const GetMyProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Profile> call() => _repository.fetchMyProfile();
}
