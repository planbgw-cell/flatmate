import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/network/api_client.dart';
import 'package:flatmate_app/core/network/api_exception.dart';
import 'package:flatmate_app/features/auth/data/repositories/dio_auth_repository.dart';
import 'package:flatmate_app/features/chat/data/repositories/dio_chat_repository.dart';
import 'package:flatmate_app/features/feed/data/repositories/dio_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/location/data/repositories/dio_location_repository.dart';
import 'package:flatmate_app/features/location/domain/models/location_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests against the FastAPI OpenAPI schema (`/api/v1`).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final (int, Object?) Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = respond(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _config = AppConfig(
  environment: AppEnvironment.production,
  apiBaseUrl: 'http://api.test/api/v1',
  appName: 'Flatmate',
  useMockApi: false,
);

const _jeongja = LocationItem(
  id: '12',
  cityName: '성남시',
  districtName: '분당구',
  dongName: '정자동',
  latitude: 37.3656,
  longitude: 127.1083,
);

Map<String, dynamic> _feedOut({
  required int id,
  required String title,
  required String publishedAt,
  int authorId = 1,
  String feedType = 'REAL_ESTATE',
}) {
  return {
    'id': id,
    'feed_type': feedType,
    'status': 'PUBLISHED',
    'title': title,
    'content': '본문 $id',
    'source': 'APP',
    'author_id': authorId,
    'address': '성남시 분당구 정자동',
    'lat': 37.3656,
    'lng': 127.1083,
    'distance_m': 0.0,
    'extra': {
      'neighborhood': '정자동',
      'price_or_condition': '보증금 500 / 월세 60',
      'thumbnail_url': 'https://picsum.photos/seed/$id/400/400',
      'author_nickname': '판매자',
      'badges': ['housing'],
      'detail_meta': {'보증금/월세': '500 / 60'},
    },
    'published_at': publishedAt,
    'created_at': publishedAt,
  };
}

Future<(ApiClient, _FakeAdapter, TokenStorage)> _client(
  (int, Object?) Function(RequestOptions options) respond, {
  bool signedIn = true,
}) async {
  final tokens = TokenStorage();
  if (signedIn) {
    await tokens.save(
      accessToken: 'jwt-abc',
      userId: '7',
      expiresIn: const Duration(hours: 1),
    );
  }
  final adapter = _FakeAdapter(respond);
  final api = ApiClient(tokens: tokens, config: _config);
  api.dio.httpClientAdapter = adapter;
  return (api, adapter, tokens);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('dev config targets the real FastAPI server', () {
    expect(AppConfig.development.apiBaseUrl, contains('121.133.47.161:8000'));
    expect(AppConfig.development.apiBaseUrl, endsWith('/api/v1'));
  });

  group('feeds', () {
    test('GET /feeds sends feed_type · lat/lng · radius_m and maps FeedOut',
        () async {
      final (api, adapter, _) = await _client(
        (_) => (
          200,
          {
            'total': 2,
            'page': 1,
            'limit': 10,
            'items': [
              _feedOut(
                id: 1,
                title: '오래된 글',
                publishedAt: '2026-10-18T03:00:00Z',
              ),
              _feedOut(
                id: 3,
                title: '새 글',
                publishedAt: '2026-10-18T04:00:00Z',
              ),
            ],
          },
        ),
      );
      final items = await DioFeedRepository(api).fetchFeeds(
        page: 1,
        category: FeedCategory.housing.name,
        location: _jeongja,
        radiusKm: 3,
      );

      final query = adapter.requests.single.queryParameters;
      expect(adapter.requests.single.path, '/feeds');
      expect(query['feed_type'], 'REAL_ESTATE');
      expect(query['lat'], 37.3656);
      expect(query['lng'], 127.1083);
      expect(query['radius_m'], 3000);
      expect(query['limit'], 10);

      expect(items.map((e) => e.title), ['새 글', '오래된 글']);
      final item = items.last;
      expect(item.id, '1');
      expect(item.category, FeedCategory.housing);
      expect(item.authorId, '1');
      expect(item.authorName, '판매자');
      expect(item.neighborhood, '정자동');
      expect(item.priceOrCondition, '보증금 500 / 월세 60');
      expect(item.description, '본문 1');
      expect(item.badges, [FeedBadge.housing]);
    });

    test('category all omits feed_type', () async {
      final (api, adapter, _) = await _client(
        (_) => (200, {'total': 0, 'page': 1, 'limit': 10, 'items': []}),
      );
      await DioFeedRepository(api).fetchFeeds(page: 1, location: _jeongja);
      expect(
        adapter.requests.single.queryParameters.containsKey('feed_type'),
        isFalse,
      );
    });

    test('POST /feeds carries Bearer JWT and FeedCreate body', () async {
      final (api, adapter, _) = await _client(
        (o) => (201, _feedOut(id: 9, title: '알바 구해요', publishedAt: '2026-10-18T05:00:00Z', feedType: 'JOB', authorId: 7)),
      );
      final created = await DioFeedRepository(api).createPost(
        FeedItem(
          id: 'f-new-1',
          title: '알바 구해요',
          neighborhood: '정자동',
          postedAt: DateTime.now(),
          priceOrCondition: '시급 11,000원',
          thumbnailUrl: 'https://picsum.photos/seed/x/400/400',
          imageUrls: const ['https://picsum.photos/seed/x/800/600', '/local/a.jpg'],
          likeCount: 0,
          chatCount: 0,
          category: FeedCategory.job,
          badges: const [FeedBadge.recruiting],
          isBumped: false,
          description: '주말 오전',
          authorName: '나의닉네임',
        ),
        location: _jeongja,
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer jwt-abc');
      final body = request.data as Map<String, dynamic>;
      expect(body['feed_type'], 'JOB');
      expect(body['title'], '알바 구해요');
      expect(body['content'], '주말 오전');
      expect(body['lat'], 37.3656);
      expect(body['lng'], 127.1083);
      expect(body['address'], '성남시 분당구 정자동');
      final extra = body['extra'] as Map<String, dynamic>;
      expect(extra['price_or_condition'], '시급 11,000원');
      expect(extra['author_nickname'], '나의닉네임');
      expect(extra['image_urls'], ['https://picsum.photos/seed/x/800/600']);
      expect(created.id, '9');
      expect(created.category, FeedCategory.job);
    });

    test('non-numeric ids resolve to null without a request', () async {
      final (api, adapter, _) = await _client((_) => (404, null));
      expect(await DioFeedRepository(api).fetchById('f-101'), isNull);
      expect(adapter.requests, isEmpty);
    });
  });

  group('auth', () {
    test('login maps TokenResponse; 401 becomes a Korean message', () async {
      final (api, adapter, _) = await _client(
        (o) => o.data['password'] == 'Flatmate123!'
            ? (
                200,
                {
                  'access_token': 'eyJ.test',
                  'token_type': 'bearer',
                  'expires_in': 3600,
                  'user': {
                    'id': 3,
                    'email': 'qa@example.com',
                    'nickname': 'QA',
                    'is_active': true,
                    'created_at': '2026-10-18T03:00:00Z',
                  },
                },
              )
            : (401, {'detail': 'Incorrect email or password'}),
        signedIn: false,
      );
      final repo = DioAuthRepository(api);
      final session =
          await repo.login(email: 'qa@example.com', password: 'Flatmate123!');
      expect(session.accessToken, 'eyJ.test');
      expect(session.expiresIn, const Duration(hours: 1));
      expect(session.user.id, '3');
      expect(adapter.requests.first.headers.containsKey('Authorization'),
          isFalse);

      await expectLater(
        repo.login(email: 'qa@example.com', password: 'wrong'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', contains('비밀번호')),
        ),
      );
    });

    test('duplicate signup (409) is reported in Korean', () async {
      final (api, _, _) = await _client(
        (_) => (409, {'detail': 'email already registered'}),
        signedIn: false,
      );
      await expectLater(
        DioAuthRepository(api).signup(
          email: 'qa@example.com',
          password: 'Flatmate123!',
          nickname: 'QA',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', '이미 가입된 이메일입니다.'),
        ),
      );
    });

    test('401 on an authenticated call clears the stored session', () async {
      final (api, _, tokens) =
          await _client((_) => (401, {'detail': 'Could not validate credentials'}));
      expect(tokens.hasValidToken, isTrue);
      await expectLater(DioAuthRepository(api).getMe(), throwsA(isA<ApiException>()));
      expect(tokens.hasValidToken, isFalse);
    });
  });

  group('chat', () {
    test('createOrGetRoom posts peer_id/feed_id; messages map isMine',
        () async {
      final (api, adapter, tokens) = await _client((o) {
        if (o.method == 'POST' && o.path == '/chats/rooms') {
          return (
            200,
            {
              'id': 5,
              'feed_id': 1,
              'user_a_id': 1,
              'user_b_id': 7,
              'last_message_at': null,
              'created_at': '2026-10-18T03:00:00Z',
            },
          );
        }
        return (
          200,
          [
            {
              'id': 11,
              'room_id': 5,
              'sender_id': 7,
              'content': '안녕하세요',
              'created_at': '2026-10-18T03:01:00Z',
            },
            {
              'id': 12,
              'room_id': 5,
              'sender_id': 1,
              'content': '네 가능합니다',
              'created_at': '2026-10-18T03:02:00Z',
            },
          ],
        );
      });
      final feeds = DioFeedRepository(api);
      final repo = DioChatRepository(api, tokens, feeds);
      final feed = FeedItem(
        id: '1',
        title: '정자동 원룸',
        neighborhood: '정자동',
        postedAt: DateTime.now(),
        priceOrCondition: '보증금 500 / 월세 60',
        thumbnailUrl: '',
        likeCount: 0,
        chatCount: 0,
        category: FeedCategory.housing,
        badges: const [],
        isBumped: false,
        authorName: '판매자',
        authorId: '1',
      );

      final room = await repo.createOrGetRoom(feed);
      final create = adapter.requests.first;
      expect(create.data, {'peer_id': 1, 'feed_id': 1});
      expect(create.headers['Authorization'], 'Bearer jwt-abc');
      expect(room.id, '5');
      expect(room.opponentName, '판매자');
      expect(room.feedTitle, '정자동 원룸');
      expect(room.lastMessage, '네 가능합니다');

      final messages = await repo.getMessages('5');
      expect(messages.map((m) => m.isMine), [true, false]);
      expect(messages.first.message, '안녕하세요');

      await expectLater(
        repo.createOrGetRoom(feed.copyWith(authorId: '7')),
        throwsA(isA<ApiException>()),
      );
    });

    test('sendMessage posts {content}', () async {
      final (api, adapter, tokens) = await _client(
        (_) => (
          201,
          {
            'id': 13,
            'room_id': 5,
            'sender_id': 7,
            'content': '내일 볼 수 있을까요?',
            'created_at': '2026-10-18T03:03:00Z',
          },
        ),
      );
      final repo = DioChatRepository(api, tokens, DioFeedRepository(api));
      final sent = await repo.sendMessage('5', '내일 볼 수 있을까요?');
      expect(adapter.requests.single.path, '/chats/rooms/5/messages');
      expect(adapter.requests.single.data, {'content': '내일 볼 수 있을까요?'});
      expect(sent.isMine, isTrue);
    });
  });

  test('locations map LocationOut and use /locations/nearest', () async {
    final (api, adapter, _) = await _client(
      (_) => (
        200,
        [
          {
            'id': 10,
            'name': '청룡동',
            'sido': '서울',
            'sigungu': '관악구',
            'dong': '청룡동',
            'lat': 37.4812,
            'lng': 126.9527,
            'distance_m': 0.0,
          },
        ],
      ),
    );
    final repo = DioLocationRepository(api);
    final nearest =
        await repo.reverseGeo(latitude: 37.4812, longitude: 126.9527);
    expect(adapter.requests.single.path, '/locations/nearest');
    expect(nearest?.fullName, '서울 관악구 청룡동');

    final results = await repo.search('관악');
    expect(adapter.requests.last.queryParameters['q'], '관악');
    expect(results.single.dongName, '청룡동');
  });
}
