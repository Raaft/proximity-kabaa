import 'package:geolocator/geolocator.dart';
import '../entities/location_entity.dart';
import '../enums/location_mode.dart';

abstract class LocationRepository {
  Future<LocationEntity> getCurrentLocation(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  });
  Future<double> computeDistanceToKaaba(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  });
  Future<double> computeBearingToKaaba(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  });
}
