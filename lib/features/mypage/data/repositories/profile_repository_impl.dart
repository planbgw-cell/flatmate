import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryStub implements ProfileRepository {
  @override
  Future<Profile> fetchMyProfile() async {
    return const Profile(
      id: 'guest',
      nickname: '게스트',
      email: 'guest@flatmate.app',
    );
  }
}
