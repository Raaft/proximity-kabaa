import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';
import '../enums/location_mode.dart';

class ComputeDistanceToKaaba {
  final LocationRepository repository;
  ComputeDistanceToKaaba(this.repository);

  Future<double> call(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) => repository.computeDistanceToKaaba(mode, accuracy: accuracy);
}
