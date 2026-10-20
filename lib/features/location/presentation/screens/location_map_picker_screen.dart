import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/location_item.dart';
import '../providers/location_provider.dart';

/// "지도에서 위치 선택": pan the map under a fixed center pin; when the camera
/// settles, the center is resolved to a dong via `reverse-geo`.
class LocationMapPickerScreen extends ConsumerStatefulWidget {
  const LocationMapPickerScreen({
    super.key,
    this.applySelection = true,
    this.showTiles = true,
    this.idleDebounce = const Duration(milliseconds: 400),
  });

  /// `false` (signup onboarding): only pop the picked dong as the route
  /// result instead of switching the current feed location.
  final bool applySelection;

  /// Off in widget tests (no network tiles).
  final bool showTiles;

  /// Wait after the last camera event before treating the map as idle.
  final Duration idleDebounce;

  @override
  ConsumerState<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState
    extends ConsumerState<LocationMapPickerScreen> {
  static const _initialZoom = 15.0;
  static const _pinSize = 48.0;

  final _mapController = MapController();
  late final LatLng _initialCenter;

  Timer? _idleTimer;
  int _lookupSeq = 0;
  LocationItem? _resolved;
  String? _error;
  bool _resolving = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentLocationProvider);
    _initialCenter = LatLng(current.latitude, current.longitude);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventWithMove) {
      // Still moving: drop any pending lookup for an outdated center.
      _idleTimer?.cancel();
      if (!_resolving) setState(() => _resolving = true);
      return;
    }
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventFlingAnimationNotStarted ||
        event is MapEventDoubleTapZoomEnd ||
        event is MapEventRotateEnd) {
      _scheduleLookup();
    }
  }

  void _scheduleLookup() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleDebounce, () {
      _lookup(_mapController.camera.center);
    });
  }

  Future<void> _lookup(LatLng center) async {
    final seq = ++_lookupSeq;
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .getReverseGeo(center.latitude, center.longitude);
      if (!mounted || seq != _lookupSeq) return;
      setState(() {
        _resolved = location;
        _resolving = false;
        _error = location == null ? '이 위치의 동 정보를 찾을 수 없어요.' : null;
      });
    } catch (e) {
      if (!mounted || seq != _lookupSeq) return;
      setState(() {
        _resolved = null;
        _resolving = false;
        _error = e is ApiException ? e.message : '동 정보를 불러오지 못했어요.';
      });
    }
  }

  Future<void> _moveToMyLocation() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(locationServiceProvider);
    try {
      final fix = await service.currentPosition();
      if (!mounted) return;
      if (!fix.isGranted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('현재 위치를 가져오지 못했어요. 위치 권한과 GPS를 확인해 주세요.'),
            action: SnackBarAction(
              label: '설정 열기',
              onPressed: service.openAppSettings,
            ),
          ),
        );
        return;
      }
      // Programmatic moves emit no MoveEnd, so resolve explicitly.
      _mapController.move(LatLng(fix.latitude!, fix.longitude!), 16);
      _scheduleLookup();
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final location = _resolved;
    if (location == null) return;
    if (widget.applySelection) {
      ref.read(myLocationsProvider.notifier).select(location);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${location.fullName}으로 설정했어요.')),
      );
    }
    context.pop(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('내 동네 위치 선택', style: AppTypography.header2),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 6,
              maxZoom: 18,
              backgroundColor: AppColors.surface,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () => _lookup(_initialCenter),
              onMapEvent: _onMapEvent,
            ),
            children: [
              if (widget.showTiles) ...[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.flatmate.flatmate_app',
                ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                  alignment: Alignment.topRight,
                ),
              ],
            ],
          ),
          // Pin tip sits exactly on the map center.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -_pinSize / 2),
                child: const Icon(
                  Icons.location_on,
                  key: ValueKey('map-picker-pin'),
                  size: _pinSize,
                  color: AppColors.primary,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FloatingActionButton.small(
                    heroTag: 'map-picker-my-location',
                    onPressed: _locating ? null : _moveToMyLocation,
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    child: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                _SelectionCard(
                  location: _resolved,
                  resolving: _resolving,
                  error: _error,
                  onConfirm: _confirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.location,
    required this.resolving,
    required this.error,
    required this.onConfirm,
  });

  final LocationItem? location;
  final bool resolving;
  final String? error;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final canConfirm = !resolving && location != null;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 선택된 동', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              height: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: resolving
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text('위치 확인 중…', style: AppTypography.bodyLarge),
                        ],
                      )
                    : Text(
                        error ?? location!.fullName,
                        key: const ValueKey('map-picker-dong'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: error != null
                            ? AppTypography.bodyLarge.copyWith(
                                color: AppColors.error,
                              )
                            : AppTypography.header2,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: canConfirm ? onConfirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '이 위치로 동 설정하기',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
