import '../entities/property.dart';

abstract class PropertyRepository {
  Future<List<Property>> fetchProperties();
  Future<Property> fetchProperty(String id);
}
