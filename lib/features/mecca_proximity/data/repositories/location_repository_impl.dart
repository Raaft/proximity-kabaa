import 'package:geolocator/geolocator.dart';
import '../../../../core/constants.dart';
import '../../../../core/utils/location_utils.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/enums/location_mode.dart';
import '../datasources/location_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationService service;

  LocationRepositoryImpl(this.service);

  @override
  Future<LocationEntity> getCurrentLocation(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) => service.getLocation(mode, accuracy: accuracy);

  @override
  Future<double> computeDistanceToKaaba(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    final loc = await getCurrentLocation(mode, accuracy: accuracy);
    return haversineDistance(loc.lat, loc.lon, kaabaLat, kaabaLon);
  }

  @override
  Future<double> computeBearingToKaaba(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    final loc = await getCurrentLocation(mode, accuracy: accuracy);
    return bearingBetween(loc.lat, loc.lon, kaabaLat, kaabaLon);
  }
}
