enum PropertyType { room, shortStay, listing }

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.monthlyRent,
    required this.type,
    this.thumbnailUrl,
    this.availableFrom,
  });

  final String id;
  final String title;
  final String address;
  final int monthlyRent;
  final PropertyType type;
  final String? thumbnailUrl;
  final DateTime? availableFrom;
}
