import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/property.dart';

part 'property_model.g.dart';

@JsonSerializable()
class PropertyModel {
  const PropertyModel({
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
  final String type;
  final String? thumbnailUrl;
  final DateTime? availableFrom;

  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyModelToJson(this);

  Property toEntity() {
    return Property(
      id: id,
      title: title,
      address: address,
      monthlyRent: monthlyRent,
      type: PropertyType.values.firstWhere(
        (value) => value.name == type,
        orElse: () => PropertyType.room,
      ),
      thumbnailUrl: thumbnailUrl,
      availableFrom: availableFrom,
    );
  }
}
