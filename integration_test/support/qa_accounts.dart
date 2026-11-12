// Throwaway QA accounts and posts over REST, so E2E runs don't depend on
// fixed seed accounts surviving server resets.
import 'package:dio/dio.dart';
import 'package:flatmate_app/features/location/data/mappers/location_mapper.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flutter_test/flutter_test.dart';

const qaPassword = 'Flatmate123!';

class QaAccount {
  const QaAccount({
    required this.email,
    required this.nickname,
    required this.id,
    required this.token,
  });

  final String email;
  final String nickname;
  final String id;
  final String token;

  Options get auth => Options(headers: {'Authorization': 'Bearer $token'});
}

/// `POST /auth/signup` + `/auth/login` for a new account.
Future<QaAccount> signUpQaAccount(
  Dio dio, {
  required String email,
  required String nickname,
}) async {
  await dio.post<dynamic>('/auth/signup', data: {
    'email': email,
    'password': qaPassword,
    'nickname': nickname,
  });
  final login = await dio.post<Map<String, dynamic>>(
    '/auth/login',
    data: {'email': email, 'password': qaPassword},
  );
  return QaAccount(
    email: email,
    nickname: nickname,
    id: (login.data!['user'] as Map)['id'].toString(),
    token: login.data!['access_token'] as String,
  );
}

/// Server dong from `GET /locations?q=` whose full name ends with [name]
/// (the label the dong picker shows, e.g. "성남시 분당구 정자동").
Future<LocationItem> findServerDong(
  Dio dio, {
  required String query,
  required String name,
}) async {
  final response = await dio.get<List<dynamic>>(
    '/locations',
    queryParameters: {'q': query, 'limit': 30},
  );
  final dongs = response.data!
      .map((e) => locationItemFromJson(Map<String, dynamic>.from(e as Map)));
  for (final dong in dongs) {
    if (dong.fullName.endsWith(name)) return dong;
  }
  throw TestFailure('No server dong "$name" for q=$query');
}

/// 원룸 listing by [author] at [dong]; returns the feed id.
Future<String> createQaRoomPost(
  Dio dio,
  QaAccount author, {
  required String title,
  required LocationItem dong,
}) async {
  final created = await dio.post<Map<String, dynamic>>(
    '/feeds',
    options: author.auth,
    data: {
      'feed_type': 'REAL_ESTATE',
      'title': title,
      'content': 'E2E 테스트용 매물입니다.',
      'location_id': ?int.tryParse(dong.id),
      'lat': dong.latitude,
      'lng': dong.longitude,
      'address': dong.fullName,
      'image_urls': const <String>[],
      'extra_meta': {
        'room_type': 'ONE_ROOM',
        'deposit': 500,
        'monthly_rent': 50,
      },
    },
  );
  return created.data!['id'].toString();
}
