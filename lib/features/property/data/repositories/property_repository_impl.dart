import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_datasource.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  PropertyRepositoryImpl(this._remote);

  final PropertyRemoteDataSource _remote;

  @override
  Future<List<Property>> fetchProperties() async {
    final models = await _remote.fetchProperties();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Property> fetchProperty(String id) async {
    final properties = await fetchProperties();
    return properties.firstWhere((property) => property.id == id);
  }
}
