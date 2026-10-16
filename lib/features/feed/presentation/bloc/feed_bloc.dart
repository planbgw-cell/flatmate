import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/feed_item.dart';
import '../../domain/usecases/get_feed_page_usecase.dart';

sealed class FeedEvent {
  const FeedEvent();
}

class FeedStarted extends FeedEvent {
  const FeedStarted();
}

class FeedRefreshed extends FeedEvent {
  const FeedRefreshed();
}

class FeedLoadMore extends FeedEvent {
  const FeedLoadMore();
}

class FeedCategoryChanged extends FeedEvent {
  const FeedCategoryChanged(this.category);

  final FeedCategory category;
}

sealed class FeedState {
  const FeedState();
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  const FeedLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.category = FeedCategory.all,
    this.isLoadingMore = false,
  });

  final List<FeedItem> items;
  final int page;
  final bool hasMore;
  final FeedCategory category;
  final bool isLoadingMore;

  List<FeedItem> get visibleItems =>
      items.where((item) => item.matchesCategory(category)).toList();

  FeedLoaded copyWith({
    List<FeedItem>? items,
    int? page,
    bool? hasMore,
    FeedCategory? category,
    bool? isLoadingMore,
  }) {
    return FeedLoaded(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      category: category ?? this.category,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class FeedFailure extends FeedState {
  const FeedFailure(this.message);

  final String message;
}

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc(this._getFeedPage) : super(const FeedInitial()) {
    on<FeedStarted>(_onStarted);
    on<FeedRefreshed>(_onRefreshed);
    on<FeedLoadMore>(_onLoadMore);
    on<FeedCategoryChanged>(_onCategoryChanged);
  }

  final GetFeedPageUseCase _getFeedPage;
  static const _pageSize = 10;

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    emit(const FeedLoading());
    try {
      final items = await _getFeedPage(page: 1, pageSize: _pageSize);
      emit(
        FeedLoaded(
          items: items,
          page: 1,
          hasMore: items.length >= _pageSize,
        ),
      );
    } catch (error) {
      emit(FeedFailure(error.toString()));
    }
  }

  Future<void> _onRefreshed(
    FeedRefreshed event,
    Emitter<FeedState> emit,
  ) async {
    final category =
        state is FeedLoaded ? (state as FeedLoaded).category : FeedCategory.all;
    try {
      final items = await _getFeedPage(page: 1, pageSize: _pageSize);
      emit(
        FeedLoaded(
          items: items,
          page: 1,
          hasMore: items.length >= _pageSize,
          category: category,
        ),
      );
    } catch (error) {
      emit(FeedFailure(error.toString()));
    }
  }

  Future<void> _onLoadMore(
    FeedLoadMore event,
    Emitter<FeedState> emit,
  ) async {
    final current = state;
    if (current is! FeedLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final more = await _getFeedPage(page: nextPage, pageSize: _pageSize);
      emit(
        FeedLoaded(
          items: [...current.items, ...more],
          page: nextPage,
          hasMore: more.length >= _pageSize,
          category: current.category,
        ),
      );
    } catch (error) {
      emit(current.copyWith(isLoadingMore: false));
      emit(FeedFailure(error.toString()));
    }
  }

  void _onCategoryChanged(
    FeedCategoryChanged event,
    Emitter<FeedState> emit,
  ) {
    final current = state;
    if (current is FeedLoaded) {
      emit(current.copyWith(category: event.category));
    }
  }
}
