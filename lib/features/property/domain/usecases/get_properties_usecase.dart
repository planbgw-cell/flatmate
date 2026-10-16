import '../entities/property.dart';
import '../repositories/property_repository.dart';

class GetPropertiesUseCase {
  const GetPropertiesUseCase(this._repository);

  final PropertyRepository _repository;

  Future<List<Property>> call() => _repository.fetchProperties();
}
