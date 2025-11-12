import 'package:geolocator/geolocator.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../enums/location_mode.dart';

class GetCurrentLocation {
  final LocationRepository repository;
  GetCurrentLocation(this.repository);

  Future<LocationEntity> call(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) => repository.getCurrentLocation(mode, accuracy: accuracy);
}
