abstract final class RouteNames {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const feed = '/feed';
  static const homeDetail = '/home/:id';
  static const feedDetail = '/feed/detail';
  static const feedDetailById = '/feed/detail/:id';
  static const shareFeed = '/share/feed/:id';
  static const property = '/property';
  static const propertyDetail = '/property/:id';
  static const jobs = '/jobs';
  static const localLife = '/local-life';
  static const myPage = '/mypage';
  static const postCreateRealEstate = '/post/create/real-estate';
  static const postCreateJob = '/post/create/job';
  static const postCreateGeneral = '/post/create/general';
  static const chat = '/chat';
  static const chatRoom = '/chat/room/:roomId';

  static String chatRoomPath(String roomId) => '/chat/room/$roomId';
  static String shareFeedPath(String id) => '/share/feed/$id';
  static String feedDetailPath(String id) => '/feed/detail/$id';
}
