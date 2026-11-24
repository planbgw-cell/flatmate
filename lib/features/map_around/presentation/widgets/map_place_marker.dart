import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../places/domain/models/local_place.dart';

class MapPlaceMarker extends StatelessWidget {
  const MapPlaceMarker({
    super.key,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  static const width = 40.0;
  static const height = 48.0;

  final LocalPlace place;
  final bool selected;
  final VoidCallback onTap;

  static Color colorFor(PlaceCategory category) => switch (category) {
        PlaceCategory.food => const Color(0xFFE85D04),
        PlaceCategory.cafe => const Color(0xFF9C6644),
        PlaceCategory.mart => const Color(0xFF2A9D8F),
        PlaceCategory.medical => const Color(0xFFE63946),
        PlaceCategory.fitness => const Color(0xFF457B9D),
        PlaceCategory.life => const Color(0xFF6A4C93),
        PlaceCategory.car => const Color(0xFF264653),
      };

  static IconData iconFor(PlaceCategory category) => switch (category) {
        PlaceCategory.food => Icons.restaurant,
        PlaceCategory.cafe => Icons.local_cafe,
        PlaceCategory.mart => Icons.storefront,
        PlaceCategory.medical => Icons.local_hospital,
        PlaceCategory.fitness => Icons.fitness_center,
        PlaceCategory.life => Icons.local_laundry_service,
        PlaceCategory.car => Icons.local_gas_station,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(place.category);
    final size = selected ? 36.0 : 30.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.white,
                width: selected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(iconFor(place.category), size: 16, color: Colors.white),
          ),
          CustomPaint(
            size: const Size(10, 8),
            painter: _PinTailPainter(color),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
