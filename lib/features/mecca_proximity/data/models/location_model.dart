import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.lat,
    required super.lon,
    required super.accuracy,
  });
}
