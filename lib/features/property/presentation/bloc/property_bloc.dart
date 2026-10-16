import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/property.dart';
import '../../domain/usecases/get_properties_usecase.dart';

sealed class PropertyEvent {
  const PropertyEvent();
}

class PropertyLoadRequested extends PropertyEvent {
  const PropertyLoadRequested();
}

sealed class PropertyState {
  const PropertyState();
}

class PropertyInitial extends PropertyState {
  const PropertyInitial();
}

class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

class PropertyLoaded extends PropertyState {
  const PropertyLoaded(this.items);

  final List<Property> items;
}

class PropertyFailure extends PropertyState {
  const PropertyFailure(this.message);

  final String message;
}

class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  PropertyBloc(this._getProperties) : super(const PropertyInitial()) {
    on<PropertyLoadRequested>(_onLoad);
  }

  final GetPropertiesUseCase _getProperties;

  Future<void> _onLoad(
    PropertyLoadRequested event,
    Emitter<PropertyState> emit,
  ) async {
    emit(const PropertyLoading());
    try {
      final items = await _getProperties();
      emit(PropertyLoaded(items));
    } catch (error) {
      emit(PropertyFailure(error.toString()));
    }
  }
}
