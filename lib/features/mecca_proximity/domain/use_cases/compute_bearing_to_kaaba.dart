import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';
import '../enums/location_mode.dart';

class ComputeBearingToKaaba {
  final LocationRepository repository;
  ComputeBearingToKaaba(this.repository);

  Future<double> call(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) => repository.computeBearingToKaaba(mode, accuracy: accuracy);
}
