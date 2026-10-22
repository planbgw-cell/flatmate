/// Feed domain model + mock catalog for Step 1-3 UI.
enum FeedCategory {
  all,
  housing,
  job,
  market,
  community;

  String get label => switch (this) {
        FeedCategory.all => '전체',
        FeedCategory.housing => '부동산/주거',
        FeedCategory.job => '단기 알바',
        FeedCategory.market => '중고/나눔',
        FeedCategory.community => '동네 소식',
      };
}

enum FeedBadge {
  shortStay,
  roommate,
  urgent,
  recruiting,
  sharing,
  bumped,
  housing,
  market,
  community;

  String get label => switch (this) {
        FeedBadge.shortStay => '단기임대',
        FeedBadge.roommate => '룸메',
        FeedBadge.urgent => '급구',
        FeedBadge.recruiting => '모집중',
        FeedBadge.sharing => '나눔',
        FeedBadge.bumped => '끌올',
        FeedBadge.housing => '주거',
        FeedBadge.market => '중고',
        FeedBadge.community => '동네',
      };
}

class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.neighborhood,
    required this.postedAt,
    required this.priceOrCondition,
    required this.thumbnailUrl,
    required this.likeCount,
    required this.chatCount,
    required this.category,
    required this.badges,
    required this.isBumped,
    this.imageUrls = const [],
    this.description = '',
    this.authorName = '이웃',
    this.authorId,
    this.authorAvatarUrl,
    this.trustScore = 36.5,
    this.ctaLabel = '채팅하기',
    this.verificationCount = 3,
    this.detailMeta = const {},
    this.extraMeta = const {},
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String neighborhood;
  final DateTime postedAt;
  final String priceOrCondition;
  final String thumbnailUrl;
  final int likeCount;
  final int chatCount;
  final FeedCategory category;
  final List<FeedBadge> badges;
  final bool isBumped;
  final List<String> imageUrls;
  final String description;
  final String authorName;

  /// Server user id of the author (chat `peer_id`); null for mock posts.
  final String? authorId;
  final String? authorAvatarUrl;
  final double trustScore;
  final String ctaLabel;
  final int verificationCount;
  final Map<String, String> detailMeta;

  /// Server `extra_meta` (typed per category, see `FeedExtraMeta`).
  final Map<String, dynamic> extraMeta;
  final bool isFavorite;

  List<String> get gallery =>
      imageUrls.isEmpty ? [thumbnailUrl] : imageUrls;

  String get ctaButtonLabel => switch (category) {
        FeedCategory.housing => '채팅으로 문의하기',
        FeedCategory.job => '지원하기',
        _ => ctaLabel,
      };

  String get trustPercentLabel {
    final pct = ((trustScore / 50.0) * 100).clamp(0, 100).round();
    return '신뢰도 $pct%';
  }

  bool matchesCategory(FeedCategory selected) {
    if (selected == FeedCategory.all) return true;
    return category == selected;
  }

  bool matchesCategoryKey(String key) {
    if (key == FeedCategory.all.name || key.isEmpty) return true;
    return category.name == key;
  }

  FeedItem copyWith({
    String? id,
    String? title,
    String? neighborhood,
    DateTime? postedAt,
    String? priceOrCondition,
    String? thumbnailUrl,
    int? likeCount,
    int? chatCount,
    FeedCategory? category,
    List<FeedBadge>? badges,
    bool? isBumped,
    List<String>? imageUrls,
    String? description,
    String? authorName,
    String? authorId,
    String? authorAvatarUrl,
    double? trustScore,
    String? ctaLabel,
    int? verificationCount,
    Map<String, String>? detailMeta,
    Map<String, dynamic>? extraMeta,
    bool? isFavorite,
  }) {
    return FeedItem(
      id: id ?? this.id,
      title: title ?? this.title,
      neighborhood: neighborhood ?? this.neighborhood,
      postedAt: postedAt ?? this.postedAt,
      priceOrCondition: priceOrCondition ?? this.priceOrCondition,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likeCount: likeCount ?? this.likeCount,
      chatCount: chatCount ?? this.chatCount,
      category: category ?? this.category,
      badges: badges ?? this.badges,
      isBumped: isBumped ?? this.isBumped,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      trustScore: trustScore ?? this.trustScore,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      verificationCount: verificationCount ?? this.verificationCount,
      detailMeta: detailMeta ?? this.detailMeta,
      extraMeta: extraMeta ?? this.extraMeta,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

extension FeedCategoryX on FeedCategory {
  static FeedCategory fromKey(String key) {
    return FeedCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => FeedCategory.all,
    );
  }
}

/// ~12 mock feed items for a rich home feed demo.
List<FeedItem> buildMockFeedItems({DateTime? now}) {
  final base = now ?? DateTime.now();
  return [
    FeedItem(
      id: 'f-101',
      title: '신촌 풀옵션 원룸 · 보증금 협의 가능',
      neighborhood: '신촌동',
      postedAt: base.subtract(const Duration(minutes: 5)),
      priceOrCondition: '보증금 500 / 월세 62',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate101/400/400',
      imageUrls: [
        'https://picsum.photos/seed/flatmate101a/800/600',
        'https://picsum.photos/seed/flatmate101b/800/600',
        'https://picsum.photos/seed/flatmate101c/800/600',
      ],
      likeCount: 8,
      chatCount: 3,
      category: FeedCategory.housing,
      badges: [FeedBadge.bumped, FeedBadge.housing],
      isBumped: true,
      description:
          '역세권 도보 3분 거리 원룸입니다. 세탁기·냉장고·에어컨 포함, 즉시 입주 가능합니다. 관리비는 수도·인터넷 포함이에요.',
      authorName: '신촌이웃',
      trustScore: 42.1,
      verificationCount: 5,
      detailMeta: {
        '보증금/월세': '500 / 62만',
        '관리비': '7만 (수도·인터넷 포함)',
        '입주 가능일': '즉시',
        '옵션': '풀옵션',
      },
    ),
    FeedItem(
      id: 'f-102',
      title: '홍대 단기임대 투룸 (최소 2주)',
      neighborhood: '서교동',
      postedAt: base.subtract(const Duration(minutes: 18)),
      priceOrCondition: '주 28만',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate102/400/400',
      imageUrls: [
        'https://picsum.photos/seed/flatmate102a/800/600',
        'https://picsum.photos/seed/flatmate102b/800/600',
      ],
      likeCount: 15,
      chatCount: 7,
      category: FeedCategory.housing,
      badges: [FeedBadge.shortStay, FeedBadge.urgent],
      isBumped: false,
      description: '출장·인턴용 단기임대. 침구·와이파이 포함. 최소 2주부터 가능합니다.',
      authorName: '홍대집주인',
      trustScore: 48.3,
      verificationCount: 8,
      detailMeta: {
        '보증금/월세': '주 28만 (단기)',
        '최소 기간': '2주',
        '포함 항목': '침구 · 와이파이',
        '입주 가능일': '협의',
      },
    ),
    FeedItem(
      id: 'f-103',
      title: '건대 카페 주말 오픈 알바 급구',
      neighborhood: '화양동',
      postedAt: base.subtract(const Duration(hours: 1)),
      priceOrCondition: '시급 11,000원',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate103/400/400',
      imageUrls: [
        'https://picsum.photos/seed/flatmate103a/800/600',
        'https://picsum.photos/seed/flatmate103b/800/600',
      ],
      likeCount: 4,
      chatCount: 12,
      category: FeedCategory.job,
      badges: [FeedBadge.urgent, FeedBadge.recruiting],
      isBumped: false,
      description: '토·일 오전 오픈 알바입니다. 경력자 우대, 교육비 지급합니다.',
      authorName: '화양카페',
      trustScore: 39.0,
      ctaLabel: '지원하기',
      verificationCount: 4,
      detailMeta: {
        '시급': '11,000원',
        '근무 요일': '토 · 일',
        '근무 시간': '07:00 ~ 13:00',
        '성별/연령': '무관 · 20대 환영',
      },
    ),
    FeedItem(
      id: 'f-104',
      title: '이대 앞 오픈형 원룸 · 룸메이트 구해요',
      neighborhood: '대현동',
      postedAt: base.subtract(const Duration(hours: 3)),
      priceOrCondition: '보증금 300 / 월세 55',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate104/400/400',
      likeCount: 22,
      chatCount: 9,
      category: FeedCategory.housing,
      badges: [FeedBadge.roommate, FeedBadge.housing],
      isBumped: false,
      description: '학교 도보 5분. 관리비 포함.',
      authorName: '대현동주민',
      trustScore: 44.7,
    ),
    FeedItem(
      id: 'f-105',
      title: '연남동 짐 옮기기 심부름',
      neighborhood: '연남동',
      postedAt: base.subtract(const Duration(hours: 5)),
      priceOrCondition: '건당 30,000원',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate105/400/400',
      likeCount: 2,
      chatCount: 5,
      category: FeedCategory.job,
      badges: [FeedBadge.recruiting],
      isBumped: false,
      description: '박스 4개, 같은 동 내 이동.',
      authorName: '연남이웃',
      trustScore: 37.2,
      ctaLabel: '지원하기',
    ),
    FeedItem(
      id: 'f-106',
      title: '합정 복층 오피스텔 · 풀옵션',
      neighborhood: '합정동',
      postedAt: base.subtract(const Duration(hours: 8)),
      priceOrCondition: '전세 1억 2천',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate106/400/400',
      likeCount: 31,
      chatCount: 14,
      category: FeedCategory.housing,
      badges: [FeedBadge.bumped, FeedBadge.housing],
      isBumped: true,
      description: '한강뷰 복층. 주차 1대.',
      authorName: '합정중개',
      trustScore: 46.5,
    ),
    FeedItem(
      id: 'f-107',
      title: '신촌 책상+의자 세트 처분',
      neighborhood: '창천동',
      postedAt: base.subtract(const Duration(days: 1)),
      priceOrCondition: '40,000원',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate107/400/400',
      likeCount: 6,
      chatCount: 2,
      category: FeedCategory.market,
      badges: [FeedBadge.market],
      isBumped: false,
      description: '이사 정리. 상태 양호. 직거래만.',
      authorName: '창천동러',
      trustScore: 41.0,
    ),
    FeedItem(
      id: 'f-108',
      title: '마포 편의점 야간 알바',
      neighborhood: '공덕동',
      postedAt: base.subtract(const Duration(days: 1, hours: 4)),
      priceOrCondition: '시급 12,000원',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate108/400/400',
      likeCount: 11,
      chatCount: 18,
      category: FeedCategory.job,
      badges: [FeedBadge.urgent, FeedBadge.recruiting],
      isBumped: false,
      description: '주 3회 야간. 교통비 별도.',
      authorName: '공덕점장',
      trustScore: 40.2,
      ctaLabel: '지원하기',
    ),
    FeedItem(
      id: 'f-109',
      title: '정자동 미니 선풍기 나눔합니다',
      neighborhood: '정자동',
      postedAt: base.subtract(const Duration(days: 1, hours: 8)),
      priceOrCondition: '나눔',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate109/400/400',
      likeCount: 19,
      chatCount: 8,
      category: FeedCategory.market,
      badges: [FeedBadge.sharing, FeedBadge.market],
      isBumped: false,
      description: '작동 잘 됩니다. 오늘 저녁 픽업 가능.',
      authorName: '정자이웃',
      trustScore: 43.0,
    ),
    FeedItem(
      id: 'f-110',
      title: '신촌 맛집 리스트 공유해요',
      neighborhood: '신촌동',
      postedAt: base.subtract(const Duration(days: 2)),
      priceOrCondition: '정보글',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate110/400/400',
      likeCount: 45,
      chatCount: 21,
      category: FeedCategory.community,
      badges: [FeedBadge.community],
      isBumped: false,
      description: '혼자 먹기 좋은 곳 모음. 댓글로 추천도 받아요.',
      authorName: '신촌맛집러',
      trustScore: 47.8,
      ctaLabel: '댓글달기',
    ),
    FeedItem(
      id: 'f-111',
      title: '연희동 단기 룸메이트 (1개월)',
      neighborhood: '연희동',
      postedAt: base.subtract(const Duration(days: 2, hours: 6)),
      priceOrCondition: '보증금 0 / 월세 45',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate111/400/400',
      likeCount: 9,
      chatCount: 4,
      category: FeedCategory.housing,
      badges: [FeedBadge.roommate, FeedBadge.shortStay],
      isBumped: false,
      description: '조용한 투룸. 여성 우대.',
      authorName: '연희동살림',
      trustScore: 44.0,
    ),
    FeedItem(
      id: 'f-112',
      title: '동네 고양이 급식소 봉사 모집',
      neighborhood: '연남동',
      postedAt: base.subtract(const Duration(days: 3)),
      priceOrCondition: '봉사',
      thumbnailUrl: 'https://picsum.photos/seed/flatmate112/400/400',
      likeCount: 27,
      chatCount: 11,
      category: FeedCategory.community,
      badges: [FeedBadge.community, FeedBadge.recruiting],
      isBumped: false,
      description: '주 1회 급식·쓰레기 수거. 초보 환영.',
      authorName: '연남캣맘',
      trustScore: 49.1,
      ctaLabel: '참여하기',
    ),
  ];
}
