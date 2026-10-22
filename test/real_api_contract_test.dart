import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmate_app/app/config/app_config.dart';
import 'package:flatmate_app/core/auth/token_refresher.dart';
import 'package:flatmate_app/core/auth/token_storage.dart';
import 'package:flatmate_app/core/network/api_client.dart';
import 'package:flatmate_app/core/network/api_exception.dart';
import 'package:flatmate_app/core/network/media_url.dart';
import 'package:flatmate_app/features/post_create/data/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flatmate_app/features/auth/data/repositories/dio_auth_repository.dart';
import 'package:flatmate_app/features/chat/data/repositories/dio_chat_repository.dart';
import 'package:flatmate_app/features/feed/data/repositories/dio_feed_repository.dart';
import 'package:flatmate_app/features/feed/domain/models/feed_item.dart';
import 'package:flatmate_app/features/feed/domain/repositories/feed_repository.dart';
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

/// Refresher of the most recent [_client] (shares the fake adapter).
late TokenRefresher _refresher;

Future<(ApiClient, _FakeAdapter, TokenStorage)> _client(
  (int, Object?) Function(RequestOptions options) respond, {
  bool signedIn = true,
  Duration accessExpiresIn = const Duration(hours: 1),
}) async {
  final tokens = TokenStorage();
  if (signedIn) {
    await tokens.save(
      accessToken: 'jwt-abc',
      refreshToken: 'refresh-xyz',
      userId: '7',
      expiresIn: accessExpiresIn,
      refreshExpiresIn: const Duration(days: 14),
    );
  }
  final adapter = _FakeAdapter(respond);
  _refresher = TokenRefresher(tokens: tokens, baseUrl: _config.apiBaseUrl)
    ..dio.httpClientAdapter = adapter;
  final api = ApiClient(tokens: tokens, refresher: _refresher, config: _config);
  api.dio.httpClientAdapter = adapter;
  return (api, adapter, tokens);
}

Map<String, dynamic> _tokenResponse(String access) => {
      'access_token': access,
      'refresh_token': 'refresh-xyz',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_expires_in': 1209600,
      'user': {
        'id': 7,
        'email': 'qa@example.com',
        'nickname': 'QA',
        'is_active': true,
        'created_at': '2026-10-18T03:00:00Z',
      },
    };

final _me = <String, dynamic>{
  'id': 7,
  'email': 'qa@example.com',
  'nickname': 'QA',
  'is_active': true,
  'created_at': '2026-10-18T03:00:00Z',
};

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

      expect(query['sort'], 'latest');
      // Server owns ordering now (`sort=`), so the client keeps it as-is.
      expect(items.map((e) => e.title), ['오래된 글', '새 글']);
      final item = items.first;
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

    test('POST /feeds carries Bearer JWT, image_urls and typed extra_meta',
        () async {
      const meta = {
        'room_type': 'ONE_ROOM',
        'deposit': 500,
        'monthly_rent': 50,
        'is_short_term': false,
      };
      final (api, adapter, _) = await _client(
        (o) => (
          201,
          {
            ..._feedOut(
              id: 9,
              title: '정자동 원룸',
              publishedAt: '2026-10-18T05:00:00Z',
              authorId: 7,
            ),
            'extra': null,
            'extra_meta': meta,
            'image_urls': ['/static/images/a.png', '/static/images/b.jpg'],
            'thumbnail_url': '/static/images/a.png',
          },
        ),
      );
      final created = await DioFeedRepository(api).createPost(
        FeedItem(
          id: 'f-new-1',
          title: '정자동 원룸',
          neighborhood: '정자동',
          postedAt: DateTime.now(),
          priceOrCondition: '',
          thumbnailUrl: '/static/images/a.png',
          imageUrls: const ['/static/images/a.png', '/static/images/b.jpg'],
          likeCount: 0,
          chatCount: 0,
          category: FeedCategory.housing,
          badges: const [],
          isBumped: false,
          description: '역세권 원룸',
          extraMeta: meta,
        ),
        location: _jeongja,
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer jwt-abc');
      final body = request.data as Map<String, dynamic>;
      expect(body['feed_type'], 'REAL_ESTATE');
      expect(body['content'], '역세권 원룸');
      expect(body['lat'], 37.3656);
      expect(body['address'], '성남시 분당구 정자동');
      expect(body['image_urls'], ['/static/images/a.png', '/static/images/b.jpg']);
      expect(body['extra_meta'], meta);
      expect(body.containsKey('extra'), isFalse);

      expect(created.id, '9');
      expect(created.imageUrls, [
        'http://121.133.47.161:8000/static/images/a.png',
        'http://121.133.47.161:8000/static/images/b.jpg',
      ]);
      expect(created.thumbnailUrl,
          'http://121.133.47.161:8000/static/images/a.png');
      expect(created.priceOrCondition, '보증금 500 / 월세 50');
      expect(created.detailMeta['방 종류'], '원룸');
      expect(created.detailMeta['보증금'], '500만원');
      expect(created.badges, [FeedBadge.housing]);
      expect(created.neighborhood, '정자동');
    });

    test('FeedOut author_nickname / profile image / price_text win', () async {
      final (api, _, _) = await _client(
        (_) => (
          200,
          {
            'total': 2,
            'page': 1,
            'limit': 10,
            'items': [
              {
                ..._feedOut(id: 7, title: '선풍기', publishedAt: '2026-10-22T00:00:00Z'),
                'feed_type': 'GENERAL',
                'extra': null,
                'extra_meta': {'price': 15000, 'is_free': false, 'can_negotiate': true},
                'author_nickname': '정자동주민',
                'author_profile_image': '/static/images/me.png',
                'price_text': '15,000원',
              },
              {
                ..._feedOut(id: 8, title: '수집 공고', publishedAt: '2026-10-22T00:00:00Z'),
                'feed_type': 'JOB',
                'extra': null,
                'extra_meta': {'pay_type': 'HOURLY', 'pay_amount': 10030},
                'author_nickname': null,
                'price_text': '시급 10,030원',
              },
            ],
          },
        ),
      );
      final items = await DioFeedRepository(api).fetchFeeds(page: 1);

      expect(items[0].authorName, '정자동주민');
      expect(items[0].authorAvatarUrl,
          'http://121.133.47.161:8000/static/images/me.png');
      expect(items[0].priceOrCondition, '15,000원');
      expect(items[0].detailMeta['가격'], '15,000원');
      expect(items[1].authorName, '이웃');
      expect(items[1].authorAvatarUrl, isNull);
      expect(items[1].priceOrCondition, '시급 10,030원');
    });

    test('typed JOB / GENERAL extra_meta derive price labels', () async {
      final (api, _, _) = await _client(
        (_) => (
          200,
          {
            'total': 2,
            'page': 1,
            'limit': 10,
            'items': [
              {
                ..._feedOut(id: 4, title: '알바', publishedAt: '2026-10-18T05:00:00Z'),
                'feed_type': 'JOB',
                'extra': null,
                'extra_meta': {
                  'pay_type': 'HOURLY',
                  'pay_amount': 11000,
                  'work_days': '토,일',
                  'work_hours': '09:00~13:00',
                },
              },
              {
                ..._feedOut(id: 5, title: '나눔', publishedAt: '2026-10-18T05:00:00Z'),
                'feed_type': 'GENERAL',
                'extra': null,
                'extra_meta': {'is_free': true, 'can_negotiate': false},
              },
            ],
          },
        ),
      );
      final items = await DioFeedRepository(api).fetchFeeds(page: 1);
      expect(items[0].priceOrCondition, '시급 11,000원');
      expect(items[0].detailMeta['근무 요일'], '토·일');
      expect(items[1].priceOrCondition, '나눔');
      expect(items[1].badges, [FeedBadge.market, FeedBadge.sharing]);
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

    test('signup sends location_id; UserOut maps primary_location', () async {
      final (api, adapter, _) = await _client(
        (_) => (
          201,
          {
            ..._me,
            'primary_location': {
              'id': 12,
              'name': '정자동',
              'full_name': '성남시 분당구 정자동',
              'sido': '경기도',
              'sigungu': '성남시 분당구',
              'dong': '정자동',
              'region_code': '4113554500',
              'lat': 37.3656,
              'lng': 127.1083,
            },
            'location_verified_at': '2026-10-20T10:17:26Z',
          },
        ),
        signedIn: false,
      );
      final user = await DioAuthRepository(api).signup(
        email: 'qa@example.com',
        password: 'Flatmate123!',
        nickname: 'QA',
        locationId: 12,
      );
      expect(adapter.requests.single.data['location_id'], 12);
      expect(user.primaryLocation?.id, '12');
      expect(user.primaryLocation?.fullName, '성남시 분당구 정자동');
      expect(user.locationVerifiedAt, DateTime.utc(2026, 10, 20, 10, 17, 26));
    });

    test('signup without a dong omits location_id', () async {
      final (api, adapter, _) = await _client(
        (_) => (201, _me),
        signedIn: false,
      );
      final user = await DioAuthRepository(api).signup(
        email: 'qa@example.com',
        password: 'Flatmate123!',
        nickname: 'QA',
      );
      expect(
        (adapter.requests.single.data as Map).containsKey('location_id'),
        isFalse,
      );
      expect(user.primaryLocation, isNull);
    });

    test('updateLocation → PATCH /auth/location {location_id}', () async {
      final (api, adapter, _) = await _client(
        (_) => (
          200,
          {
            ..._me,
            'primary_location': {
              'id': 10,
              'name': '청룡동',
              'full_name': '관악구 청룡동',
              'dong': '청룡동',
              'lat': 37.4812,
              'lng': 126.9527,
            },
          },
        ),
      );
      final user = await DioAuthRepository(api).updateLocation(10);
      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/auth/location');
      expect(request.data, {'location_id': 10});
      expect(request.headers['Authorization'], 'Bearer jwt-abc');
      expect(user.primaryLocation?.fullName, '관악구 청룡동');
    });

    test('401 → POST /auth/refresh once → replays requests with new token',
        () async {
      final (api, adapter, tokens) = await _client((o) {
        if (o.path == '/auth/refresh') return (200, _tokenResponse('jwt-new'));
        final auth = o.headers['Authorization'];
        return auth == 'Bearer jwt-new'
            ? (200, _me)
            : (401, {'detail': 'Could not validate credentials'});
      });
      final repo = DioAuthRepository(api);

      final results = await Future.wait([repo.getMe(), repo.getMe()]);

      expect(results.map((u) => u.id), ['7', '7']);
      final refreshCalls =
          adapter.requests.where((r) => r.path == '/auth/refresh').toList();
      expect(refreshCalls, hasLength(1));
      expect(refreshCalls.single.data, {'refresh_token': 'refresh-xyz'});
      expect(refreshCalls.single.headers.containsKey('Authorization'), isFalse);
      expect(tokens.accessToken, 'jwt-new');
      expect(tokens.hasSession, isTrue);
    });

    test('locally expired access token is refreshed before the request',
        () async {
      final (api, adapter, tokens) = await _client(
        (o) => o.path == '/auth/refresh'
            ? (200, _tokenResponse('jwt-new'))
            : (200, _me),
        accessExpiresIn: Duration.zero,
      );
      await DioAuthRepository(api).getMe();
      expect(adapter.requests.map((r) => r.path), ['/auth/refresh', '/auth/me']);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer jwt-new');
      expect(tokens.isAccessTokenFresh, isTrue);
    });

    test('rejected refresh token clears the session and flags expiry',
        () async {
      final (api, _, tokens) = await _client(
        (o) => o.path == '/auth/refresh'
            ? (401, {'detail': 'Invalid or expired refresh token'})
            : (401, {'detail': 'Could not validate credentials'}),
      );
      await expectLater(
        DioAuthRepository(api).getMe(),
        throwsA(isA<ApiException>()),
      );
      expect(tokens.hasSession, isFalse);
      expect(tokens.sessionExpired, isTrue);
    });

    test('login stores both tokens', () async {
      final (api, _, _) = await _client(
        (_) => (200, _tokenResponse('jwt-login')),
        signedIn: false,
      );
      final session = await DioAuthRepository(api)
          .login(email: 'qa@example.com', password: 'Flatmate123!');
      expect(session.refreshToken, 'refresh-xyz');
      expect(session.refreshExpiresIn, const Duration(days: 14));
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
              'peer_id': 1,
              'peer_nickname': '판매자닉',
              'peer_profile_image': null,
              'last_message': '네 가능합니다',
              'last_message_at': '2026-10-18T03:02:00Z',
              'unread_count': 2,
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
              'read_at': '2026-10-18T03:01:30Z',
              'is_read': true,
            },
            {
              'id': 12,
              'room_id': 5,
              'sender_id': 1,
              'content': '네 가능합니다',
              'created_at': '2026-10-18T03:02:00Z',
              'read_at': null,
              'is_read': false,
            },
          ],
        );
      });
      final repo = DioChatRepository(api, tokens, _refresher);
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
      final create = adapter.requests.single;
      expect(create.data, {'peer_id': 1, 'feed_id': 1});
      expect(create.headers['Authorization'], 'Bearer jwt-abc');
      expect(room.id, '5');
      expect(room.opponentName, '판매자닉');
      expect(room.unreadCount, 2);
      expect(room.feedTitle, '정자동 원룸');
      expect(room.lastMessage, '네 가능합니다');

      final messages = await repo.getMessages('5');
      expect(messages.map((m) => m.isMine), [true, false]);
      expect(messages.map((m) => m.isRead), [true, false]);
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
      final repo =
          DioChatRepository(api, tokens, _refresher);
      final sent = await repo.sendMessage('5', '내일 볼 수 있을까요?');
      expect(adapter.requests.single.path, '/chats/rooms/5/messages');
      expect(adapter.requests.single.data, {'content': '내일 볼 수 있을까요?'});
      expect(sent.isMine, isTrue);

      await repo.markRoomRead('5');
      expect(adapter.requests.last.path, '/chats/rooms/5/read');
      expect(adapter.requests.last.method, 'POST');
    });

    test('room list binds peer/unread/last message with no per-room calls',
        () async {
      final (api, adapter, tokens) = await _client((o) {
        if (o.path == '/chats/rooms') {
          return (
            200,
            [
              for (final id in [1, 2])
                {
                  'id': id,
                  'feed_id': 100 + id,
                  'user_a_id': 7,
                  'user_b_id': 10 + id,
                  'peer_id': 10 + id,
                  'peer_nickname': '이웃$id',
                  'last_message': '메시지$id',
                  'last_message_at': '2026-10-18T0$id:00:00Z',
                  'unread_count': id,
                  'feed_title': '매물$id',
                  'feed_thumbnail': '/static/images/room$id.png',
                  'feed_price_text': '${id}5,000원',
                  'created_at': '2026-10-18T00:00:00Z',
                },
            ],
          );
        }
        return (404, null);
      });
      final rooms =
          await DioChatRepository(api, tokens, _refresher).getChatRooms();
      // Single request: no per-room /feeds/{id} lookups.
      expect(adapter.requests.map((r) => r.path), ['/chats/rooms']);
      expect(rooms.map((r) => r.opponentName), ['이웃2', '이웃1']);
      expect(rooms.map((r) => r.unreadCount), [2, 1]);
      expect(rooms.first.lastMessage, '메시지2');
      expect(rooms.first.feedTitle, '매물2');
      expect(rooms.first.feedPrice, '25,000원');
      expect(
        rooms.first.feedThumbnail,
        'http://121.133.47.161:8000/static/images/room2.png',
      );
    });
  });

  group('uploads', () {
    test('POST /uploads/images sends multipart files in order', () async {
      final dir = await Directory.systemTemp.createTemp('flatmate_upload');
      // Unread multipart streams keep the files open on Windows.
      addTearDown(() => dir.delete(recursive: true).catchError((_) => dir));
      final png = File('${dir.path}/a.png')..writeAsBytesSync([1, 2, 3]);
      final heic = File('${dir.path}/b')..writeAsBytesSync([4, 5]);

      final (api, adapter, _) = await _client(
        (_) => (200, ['/static/images/x.png', '/static/images/y.jpg']),
      );
      final urls = await DioImageUploadService(api)
          .upload([XFile(png.path), XFile(heic.path)]);

      final request = adapter.requests.single;
      expect(request.path, '/uploads/images');
      expect(request.headers['Authorization'], 'Bearer jwt-abc');
      final form = request.data as FormData;
      expect(form.files.map((f) => f.key), ['files', 'files']);
      expect(form.files.map((f) => f.value.filename), ['a.png', 'b.jpg']);
      expect(
        form.files.map((f) => f.value.contentType?.mimeType),
        ['image/png', 'image/jpeg'],
      );
      expect(urls, ['/static/images/x.png', '/static/images/y.jpg']);
    });

    test('no photos → no request', () async {
      final (api, adapter, _) = await _client((_) => (200, const []));
      expect(await DioImageUploadService(api).upload(const []), isEmpty);
      expect(adapter.requests, isEmpty);
    });
  });

  test('resolveMediaUrl keeps absolute URLs and prefixes relative ones', () {
    expect(
      resolveMediaUrl('/static/images/a.png', apiBaseUrl: 'http://h:8000/api/v1'),
      'http://h:8000/static/images/a.png',
    );
    expect(resolveMediaUrl('https://cdn/x.png'), 'https://cdn/x.png');
    expect(resolveMediaUrl(null), '');
  });

  test('GET /feeds forwards sort (distance needs coordinates)', () async {
    final (api, adapter, _) = await _client(
      (_) => (200, {'total': 0, 'page': 1, 'limit': 10, 'items': []}),
    );
    final repo = DioFeedRepository(api);
    await repo.fetchFeeds(page: 1, location: _jeongja, sort: FeedSort.distance);
    await repo.fetchFeeds(page: 1, sort: FeedSort.distance);
    expect(adapter.requests[0].queryParameters['sort'], 'distance');
    expect(adapter.requests[1].queryParameters['sort'], 'latest');
  });

  group('locations', () {
    test('getReverseGeo calls /locations/reverse-geo and maps ReverseGeoOut',
        () async {
      final (api, adapter, _) = await _client(
        (_) => (
          200,
          {
            'location': {
              'id': 12,
              'name': '정자동',
              'full_name': '성남시 분당구 정자동',
              'sido': '경기도',
              'sigungu': '성남시 분당구',
              'dong': '정자동',
              'region_code': '4113554500',
              'lat': 37.3656,
              'lng': 127.1083,
              'distance_m': null,
            },
            'source': 'kakao',
            'cache_distance_m': null,
          },
        ),
      );
      final location =
          await DioLocationRepository(api).getReverseGeo(37.3659, 127.1081);

      final request = adapter.requests.single;
      expect(request.path, '/locations/reverse-geo');
      expect(request.queryParameters, {'lat': 37.3659, 'lng': 127.1081});
      expect(location?.id, '12');
      expect(location?.dongName, '정자동');
      expect(location?.serverFullName, '성남시 분당구 정자동');
      expect(location?.fullName, '성남시 분당구 정자동');
      expect(location?.regionCode, '4113554500');
      expect(location?.latitude, 37.3656);
    });

    test('getReverseGeo returns null without a location payload', () async {
      final (api, _, _) = await _client((_) => (200, {'source': 'db'}));
      expect(
        await DioLocationRepository(api).getReverseGeo(37.0, 127.0),
        isNull,
      );
    });

    test('search maps LocationOut; fullName falls back to sido/sigungu/dong',
        () async {
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
            },
          ],
        ),
      );
      final results = await DioLocationRepository(api).search('관악');
      expect(adapter.requests.single.queryParameters['q'], '관악');
      expect(results.single.dongName, '청룡동');
      expect(results.single.fullName, '서울 관악구 청룡동');
    });
  });
}
