import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/models/feed_item.dart';
import '../../../location/domain/models/location_item.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../places/domain/models/local_place.dart';
import '../../domain/map_browse_mode.dart';
import '../../domain/map_feed_group.dart';
import '../providers/map_around_provider.dart';
import '../widgets/map_category_icon_bar.dart';
import '../widgets/map_feed_carousel.dart';
import '../widgets/map_feed_marker.dart';
import '../widgets/map_place_card.dart';
import '../widgets/map_place_marker.dart';

/// Tab — 동네지도: feed pins or nearby places on an OSM map.
class MapAroundScreen extends ConsumerStatefulWidget {
  const MapAroundScreen({super.key});

  @override
  ConsumerState<MapAroundScreen> createState() => _MapAroundScreenState();
}

class _MapAroundScreenState extends ConsumerState<MapAroundScreen> {
  static const _zoom = 14.0;
  static const _focusZoom = 15.0;

  /// Map drag beyond this offers "이 지역 재검색".
  static const _researchKm = 0.3;

  final _mapController = MapController();
  final _pageController = PageController(viewportFraction: 0.88);

  late final LatLng _initialCenter;
  late final double _initialZoom;
  bool _mapReady = false;
  bool _showResearch = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final focus = ref.read(mapFocusProvider);
    final focusAt = focus == null ? null : feedPosition(focus);
    final dong = ref.read(currentLocationProvider);
    _initialCenter = focusAt == null
        ? LatLng(dong.latitude, dong.longitude)
        : LatLng(focusAt.lat, focusAt.lng);
    _initialZoom = focusAt == null ? _zoom : _focusZoom;
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocus(focus));
    }
  }

  Future<void> _applyFocus(FeedItem item) async {
    if (!mounted) return;
    ref.read(mapFocusProvider.notifier).state = null;
    final position = feedPosition(item);
    if (position == null) return;
    _moveTo(position.lat, position.lng, zoom: _focusZoom);
    setState(() {
      _searching = true;
      _showResearch = false;
    });
    await ref.read(mapAroundProvider.notifier).focus(item);
    if (!mounted) return;
    setState(() => _searching = false);
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _moveTo(double lat, double lng, {double? zoom}) {
    if (!_mapReady) return;
    _mapController.move(
      LatLng(lat, lng),
      zoom ?? _mapController.camera.zoom,
    );
  }

  void _onMapEvent(MapEvent event) {
    final userMoveEnded = event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd;
    if (!userMoveEnded) return;
    final current = ref.read(mapAroundProvider).value;
    if (current == null) return;
    final center = event.camera.center;
    final movedKm = LocationItem.distanceKmBetween(
      current.centerLat,
      current.centerLng,
      center.latitude,
      center.longitude,
    );
    final show = movedKm >= _researchKm;
    if (show != _showResearch) setState(() => _showResearch = show);
  }

  Future<void> _search(double lat, double lng) async {
    setState(() {
      _searching = true;
      _showResearch = false;
    });
    await ref.read(mapAroundProvider.notifier).searchAt(lat, lng);
    if (!mounted) return;
    setState(() => _searching = false);
  }

  Future<void> _researchHere() async {
    if (!_mapReady) return;
    final center = _mapController.camera.center;
    await _search(center.latitude, center.longitude);
  }

  Future<void> _recenter() async {
    final dong = ref.read(currentLocationProvider);
    _moveTo(dong.latitude, dong.longitude, zoom: _zoom);
    await _search(dong.latitude, dong.longitude);
  }

  Future<void> _onModeChanged(MapBrowseMode mode) async {
    setState(() {
      _searching = true;
      _showResearch = false;
    });
    await ref.read(mapAroundProvider.notifier).setMode(mode);
    if (!mounted) return;
    setState(() => _searching = false);
  }

  void _onMarkerTap(MapFeedGroup group) {
    ref.read(mapAroundProvider.notifier).select(group);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      if ((_pageController.page ?? 0).round() != 0) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onPlaceTap(LocalPlace place) {
    ref.read(mapAroundProvider.notifier).selectPlace(place);
    _moveTo(place.lat, place.lng);
  }

  void _onPageChanged(List<FeedItem> items, int index) {
    if (index >= items.length) return;
    final item = items[index];
    ref.read(mapAroundProvider.notifier).selectFeed(item.id);
    final position = feedPosition(item);
    if (position != null) _moveTo(position.lat, position.lng);
  }

  void _open(FeedItem item) => context.push(RouteNames.feedDetail, extra: item);

  @override
  Widget build(BuildContext context) {
    final dong = ref.watch(currentLocationProvider);
    final aroundAsync = ref.watch(mapAroundProvider);
    final around = aroundAsync.value;
    final showTiles = ref.watch(mapTilesEnabledProvider);
    final mode = around?.mode ?? MapBrowseMode.feeds;

    ref.listen(mapFocusProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocus(next));
    });
    ref.listen(currentLocationProvider, (previous, next) {
      _moveTo(next.latitude, next.longitude, zoom: _zoom);
      if (_showResearch) setState(() => _showResearch = false);
    });
    ref.listen(mapAroundProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      final newSearch = after != null &&
          (before == null ||
              before.centerLat != after.centerLat ||
              before.centerLng != after.centerLng ||
              before.mode != after.mode);
      if (newSearch && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      final message = after?.message;
      if (message != null && message != before?.message && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          ref.read(mapAroundProvider.notifier).clearMessage();
        });
      }
    });

    final selectedGroup = around?.selectedGroup;
    final groups = [
      ...?around?.groups.where((g) => g != selectedGroup),
      ?selectedGroup,
    ];
    final places = around?.places ?? const <LocalPlace>[];
    final selectedPlace = around?.selectedPlace;
    final loading = _searching || (aroundAsync.isLoading && around == null);
    final circleRadiusM = mode.isFeeds
        ? MapAroundNotifier.radiusKm * 1000
        : MapAroundNotifier.placesRadiusM.toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('동네지도 · ${dong.dongName}', style: AppTypography.header2),
      ),
      body: Column(
        children: [
          MapCategoryIconBar(
            mode: mode,
            onChanged: _searching ? (_) {} : _onModeChanged,
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  key: const ValueKey('map-around'),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _initialZoom,
                    minZoom: 8,
                    maxZoom: 18,
                    backgroundColor: AppColors.surface,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () => _mapReady = true,
                    onMapEvent: _onMapEvent,
                  ),
                  children: [
                    if (showTiles) ...[
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.flatmate.flatmate_app',
                      ),
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                        alignment: Alignment.topRight,
                      ),
                    ],
                    if (around != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(around.centerLat, around.centerLng),
                            radius: circleRadiusM,
                            useRadiusInMeter: true,
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderColor:
                                AppColors.primary.withValues(alpha: 0.45),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    if (mode.isFeeds)
                      MarkerLayer(
                        markers: [
                          for (final group in groups)
                            Marker(
                              key: ValueKey('map-marker-${group.id}'),
                              point: LatLng(group.latitude, group.longitude),
                              width: MapFeedMarker.width,
                              height: MapFeedMarker.height,
                              alignment: Alignment.topCenter,
                              child: MapFeedMarker(
                                group: group,
                                selected: group == selectedGroup,
                                onTap: () => _onMarkerTap(group),
                              ),
                            ),
                        ],
                      )
                    else
                      MarkerLayer(
                        markers: [
                          for (final place in places)
                            Marker(
                              key: ValueKey('map-place-${place.placeId}'),
                              point: LatLng(place.lat, place.lng),
                              width: MapPlaceMarker.width,
                              height: MapPlaceMarker.height,
                              alignment: Alignment.topCenter,
                              child: MapPlaceMarker(
                                place: place,
                                selected:
                                    place.placeId == selectedPlace?.placeId,
                                onTap: () => _onPlaceTap(place),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                if (loading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_showResearch)
                  Positioned(
                    top: AppSpacing.sm,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FilledButton.icon(
                        key: const ValueKey('map-research'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 3,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _searching ? null : _researchHere,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('이 지역 재검색'),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: FloatingActionButton.small(
                          key: const ValueKey('map-recenter'),
                          heroTag: 'map-recenter',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          tooltip: '내 동네로',
                          onPressed: _searching ? null : _recenter,
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                      _bottom(aroundAsync, around),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottom(AsyncValue<MapAroundState> aroundAsync, MapAroundState? around) {
    if (around == null) {
      if (!aroundAsync.hasError) return const SizedBox.shrink();
      final error = aroundAsync.error;
      return _InfoCard(
        text: error is ApiException ? error.message : '주변 정보를 불러오지 못했어요.',
        actionLabel: '다시 시도',
        onAction: () => ref.invalidate(mapAroundProvider),
      );
    }
    if (!around.mode.isFeeds) {
      final place = around.selectedPlace;
      if (around.places.isEmpty) {
        return _InfoCard(
          key: const ValueKey('map-places-empty'),
          text: around.message ?? '이 지역에 결과가 없어요. 지도를 옮긴 뒤 재검색해 보세요.',
        );
      }
      if (place == null) return const SizedBox.shrink();
      return MapPlaceCard(place: place);
    }
    if (around.items.isEmpty) {
      return const _InfoCard(
        key: ValueKey('map-empty'),
        text: '주변 3km 안에 게시글이 없어요.',
      );
    }
    return MapFeedCarousel(
      controller: _pageController,
      items: around.items,
      selectedId: around.selectedId,
      onPageChanged: (index) => _onPageChanged(around.items, index),
      onOpen: _open,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: AppColors.cardBackground,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text(text, style: AppTypography.bodyMedium)),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
