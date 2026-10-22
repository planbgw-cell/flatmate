import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/token_storage.dart';
import '../../core/di/injection.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/chat/domain/models/chat_room.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/feed/domain/models/feed_item.dart';
import '../../features/feed/presentation/pages/feed_detail_page.dart';
import '../../features/feed/presentation/screens/feed_detail_screen.dart';
import '../../features/location/presentation/screens/location_map_picker_screen.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/main/presentation/screens/tab_screens.dart';
import '../../features/post_create/presentation/screens/general_create_screen.dart';
import '../../features/post_create/presentation/screens/job_create_screen.dart';
import '../../features/post_create/presentation/screens/real_estate_create_screen.dart';
import '../../features/property/presentation/bloc/property_bloc.dart';
import '../../features/property/presentation/pages/property_detail_page.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Screens that call JWT-protected APIs (`POST /feeds`, `/chats/*`).
const _protectedPrefixes = [
  '/post/create',
  RouteNames.chat,
  RouteNames.localLife,
];

/// Re-runs redirects only when the session is lost (logout / refresh failure).
///
/// Login and access-token rotation also notify [TokenStorage]; refreshing the
/// router then would rebuild pushed pages (e.g. a login pushed from a shell
/// tab) as new States and drop their in-flight work.
class _SessionLossListenable extends ChangeNotifier {
  _SessionLossListenable(this._tokens) : _hadSession = _tokens.hasSession {
    _tokens.addListener(_onTokensChanged);
  }

  final TokenStorage _tokens;
  bool _hadSession;

  void _onTokensChanged() {
    final hasSession = _tokens.hasSession;
    if (_hadSession && !hasSession) notifyListeners();
    _hadSession = hasSession;
  }

  @override
  void dispose() {
    _tokens.removeListener(_onTokensChanged);
    super.dispose();
  }
}

/// Post form routes open in edit mode when pushed with the post as `extra`.
FeedItem? _editTarget(GoRouterState state) {
  final extra = state.extra;
  return extra is FeedItem ? extra : null;
}

GoRouter createAppRouter({String? initialLocation}) {
  final tokens = sl<TokenStorage>();
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation ?? RouteNames.splash,
    refreshListenable: _SessionLossListenable(tokens),
    redirect: (context, state) {
      final path = state.uri.path;
      const authPaths = [RouteNames.login, RouteNames.signUp, RouteNames.splash];
      if (authPaths.contains(path)) return null;
      final isProtected = _protectedPrefixes.any(path.startsWith);
      // Refresh token rejected → back to login from anywhere.
      if (tokens.sessionExpired || (isProtected && !tokens.hasSession)) {
        return RouteNames.loginPath(state.uri.toString());
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.feed,
        redirect: (context, state) => RouteNames.home,
      ),
      GoRoute(
        path: RouteNames.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: RouteNames.signUp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SignUpScreen(
          redirectTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: RouteNames.feedDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is FeedItem) {
            return FeedDetailScreen(item: extra);
          }
          return const Scaffold(
            body: Center(child: Text('게시글 정보가 없습니다.')),
          );
        },
      ),
      GoRoute(
        path: RouteNames.feedDetailById,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FeedDetailPage(feedId: id);
        },
      ),
      GoRoute(
        path: RouteNames.shareFeed,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FeedDetailPage(feedId: id);
        },
      ),
      GoRoute(
        path: '/home/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FeedDetailPage(feedId: id);
        },
      ),
      GoRoute(
        path: '/property/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailPage(propertyId: id);
        },
      ),
      GoRoute(
        path: RouteNames.postCreateRealEstate,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RealEstateCreateScreen(targetFeed: _editTarget(state)),
      ),
      GoRoute(
        path: RouteNames.postCreateJob,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            JobCreateScreen(targetFeed: _editTarget(state)),
      ),
      GoRoute(
        path: RouteNames.postCreateGeneral,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            GeneralCreateScreen(targetFeed: _editTarget(state)),
      ),
      GoRoute(
        path: RouteNames.locationMapPicker,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocationMapPickerScreen(
          applySelection: state.uri.queryParameters['apply'] != 'false',
        ),
      ),
      GoRoute(
        path: RouteNames.chat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: RouteNames.chatRoom,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final extra = state.extra;
          return ChatRoomScreen(
            roomId: roomId,
            fallbackRoom: extra is ChatRoom ? extra : null,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.property,
                builder: (context, state) => const RealEstateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.jobs,
                builder: (context, state) => const JobsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.localLife,
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.myPage,
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppBlocProviders extends StatelessWidget {
  const AppBlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PropertyBloc>()),
      ],
      child: child,
    );
  }
}
