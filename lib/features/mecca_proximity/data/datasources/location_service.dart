import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../../domain/enums/location_mode.dart';

class LocationService {
  static const _insideMataf = LocationModel(
    lat: 21.423386,
    lon: 39.826206,
    accuracy: 1,
  );
  static const _insideHaram = LocationModel(
    lat: 21.424395,
    lon: 39.828255,
    accuracy: 1,
  );
  static const _outsideHaram = LocationModel(
    lat: 21.422487,
    lon: 39.832002,
    accuracy: 1,
  );

  Future<LocationModel> getLocation(
    LocationMode mode, {
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    return switch (mode) {
      LocationMode.insideHaram => _insideHaram,
      LocationMode.insideMataf => _insideMataf,
      LocationMode.outsideHaram => _outsideHaram,
      LocationMode.real => await _getRealLocation(accuracy: accuracy),
    };
  }

  Future<LocationModel> _getRealLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Location permission not granted');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: const Duration(seconds: 10),
    );
    return LocationModel(
      lat: pos.latitude,
      lon: pos.longitude,
      accuracy: pos.accuracy,
    );
  }
}
