// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) =>
    PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      monthlyRent: (json['monthlyRent'] as num).toInt(),
      type: json['type'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      availableFrom: json['availableFrom'] == null
          ? null
          : DateTime.parse(json['availableFrom'] as String),
    );

Map<String, dynamic> _$PropertyModelToJson(PropertyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'address': instance.address,
      'monthlyRent': instance.monthlyRent,
      'type': instance.type,
      'thumbnailUrl': instance.thumbnailUrl,
      'availableFrom': instance.availableFrom?.toIso8601String(),
    };
