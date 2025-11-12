import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants.dart';
import '../../data/models/location_reading_model.dart';
import '../../../../core/utils/location_utils.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/enums/location_mode.dart';
import '../../domain/use_cases/compute_distance_to_kaaba.dart';
import '../../domain/use_cases/compute_bearing_to_kaaba.dart';
import '../../domain/use_cases/get_current_location.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final GetCurrentLocation getCurrentLocation;
  final ComputeDistanceToKaaba computeDistanceToKaaba;
  final ComputeBearingToKaaba computeBearingToKaaba;

  Timer? _locationTimer;
  DateTime? _boostStartTime;
  final List<Map<String, double>> _locationHistory = [];
  int _stillnessCount = 0;
  bool _isStill = false;
  UpdateLocationSuccess? _lastLocationState;

  LocationCubit({
    required this.getCurrentLocation,
    required this.computeDistanceToKaaba,
    required this.computeBearingToKaaba,
  }) : super(const LocationInitial());

  void startLocationUpdates() => _checkPermissionsAndStart();
  void retryPermissionCheck() => _checkPermissionsAndStart();

  Future<void> _checkPermissionsAndStart() async {
    if (isClosed) return;

    emit(const StartLocationUpdatesLoading());

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        if (!isClosed) {
          emit(const LocationPermissionPermanentlyDenied());
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!isClosed) {
          emit(const LocationPermissionDenied());
        }
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!isClosed) {
          emit(
            const StartLocationUpdatesError(
              'Location services are disabled. Please enable GPS.',
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (!isClosed) {
          emit(const StartLocationUpdatesSuccess());
          _updateLocation();
          _scheduleNextUpdate();
        }
      } else {
        if (!isClosed) {
          emit(
            const StartLocationUpdatesError(
              'Location permission status unknown. Please try again.',
            ),
          );
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          StartLocationUpdatesError(
            'Error checking permissions: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _updateLocation() async {
    if (!isClosed) {
      final previousState = _lastLocationState;

      try {
        final currentState = _lastLocationState;
        final mode = currentState?.simulationMode ?? LocationMode.real;

        final currentDistance = currentState?.distance ?? 2000.0;
        final powerMode = _determinePowerMode(
          currentDistance,
          currentState?.manualPowerSaving ?? false,
        );
        final accuracy = _getLocationAccuracy(powerMode);

        final location = await getCurrentLocation(mode, accuracy: accuracy);

        _locationHistory.add({'lat': location.lat, 'lon': location.lon});
        if (_locationHistory.length > movingMedianWindow) {
          _locationHistory.removeAt(0);
        }

        final smoothedCoords = _locationHistory.length >= movingMedianWindow
            ? movingMedian(_locationHistory)
            : {'lat': location.lat, 'lon': location.lon};

        final smoothedLocation = LocationEntity(
          lat: smoothedCoords['lat']!,
          lon: smoothedCoords['lon']!,
          accuracy: location.accuracy,
        );

        final distance = haversineDistance(
          smoothedLocation.lat,
          smoothedLocation.lon,
          kaabaLat,
          kaabaLon,
        );
        final bearing = bearingBetween(
          smoothedLocation.lat,
          smoothedLocation.lon,
          kaabaLat,
          kaabaLon,
        );

        _checkStillness(
          smoothedLocation.lat,
          smoothedLocation.lon,
          currentState,
        );

        final updatedPowerMode = _determinePowerMode(
          distance,
          currentState?.manualPowerSaving ?? false,
        );
        final classification = _classifyLocation(distance);

        final reading = LocationReadingModel(
          lat: smoothedLocation.lat,
          lon: smoothedLocation.lon,
          accuracy: smoothedLocation.accuracy,
          timestamp: DateTime.now(),
        );

        final previousReadings = currentState?.readings ?? [];
        final previousFirstReading = previousReadings.isNotEmpty
            ? previousReadings.first
            : null;

        final updatedReadings = <LocationReadingModel>[
          reading,
          ...previousReadings,
        ].take(10).toList();

        final logsUpdated =
            updatedReadings.isNotEmpty &&
            updatedReadings.first.timestamp == reading.timestamp &&
            updatedReadings.first.lat == reading.lat &&
            updatedReadings.first.lon == reading.lon &&
            (previousFirstReading == null ||
                previousFirstReading.timestamp != reading.timestamp ||
                previousFirstReading.lat != reading.lat ||
                previousFirstReading.lon != reading.lon);

        if (!isClosed && logsUpdated) {
          final newState = UpdateLocationSuccess(
            distance: distance,
            bearing: bearing,
            powerMode: updatedPowerMode,
            classification: classification,
            readings: updatedReadings,
            isSimulationActive: currentState?.isSimulationActive ?? false,
            simulationMode: currentState?.simulationMode,
            manualPowerSaving: currentState?.manualPowerSaving ?? false,
            lastUpdate: DateTime.now(),
          );
          _lastLocationState = newState;
          emit(newState);
        }
      } catch (e) {
        if (!isClosed) {
          final errorMsg = e.toString().toLowerCase();
          if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
            _checkPermissionsAndStart();
          } else {
            emit(
              UpdateLocationError(e.toString(), previousState: previousState),
            );
          }
        }
      }
    }
  }

  void _checkStillness(
    double lat,
    double lon,
    UpdateLocationSuccess? currentState,
  ) {
    if (currentState == null || currentState.readings.isEmpty) {
      _stillnessCount = 0;
      _isStill = false;
      return;
    }

    final lastReading = currentState.readings.first;
    final movement = haversineDistance(
      lat,
      lon,
      lastReading.lat,
      lastReading.lon,
    );

    if (movement < stillnessThresholdM) {
      _stillnessCount++;
      _isStill = _stillnessCount >= 5;
    } else {
      _stillnessCount = 0;
      _isStill = false;
    }
  }

  PowerMode _determinePowerMode(double distance, bool manualPowerSaving) {
    if (manualPowerSaving) return PowerMode.lowPower;

    if (distance > 1000) {
      _boostStartTime = null;
      return PowerMode.lowPower;
    }
    if (distance > 300) {
      _boostStartTime = null;
      return PowerMode.medium;
    }

    if (_boostStartTime != null) {
      if (DateTime.now().difference(_boostStartTime!) < boostDuration) {
        return PowerMode.boost;
      }
      _boostStartTime = null;
      return PowerMode.medium;
    }

    _boostStartTime = DateTime.now();
    return PowerMode.boost;
  }

  LocationClassification _classifyLocation(double distance) {
    if (distance <= matafRadiusM) return LocationClassification.insideMataf;
    if (distance <= innerHaramRadiusM) {
      return LocationClassification.insideHaram;
    }
    return LocationClassification.outsideRange;
  }

  LocationAccuracy _getLocationAccuracy(PowerMode mode) {
    return switch (mode) {
      PowerMode.lowPower => LocationAccuracy.medium,
      PowerMode.medium => LocationAccuracy.medium,
      PowerMode.boost => LocationAccuracy.high,
    };
  }

  Duration _getUpdateInterval(UpdateLocationSuccess? currentState) {
    if (currentState?.manualPowerSaving ?? false)
      return const Duration(seconds: 30);

    final baseInterval = switch (currentState?.powerMode ??
        PowerMode.lowPower) {
      PowerMode.lowPower => const Duration(seconds: 30),
      PowerMode.medium => const Duration(seconds: 10),
      PowerMode.boost => const Duration(seconds: 3),
    };

    return _isStill
        ? Duration(seconds: baseInterval.inSeconds * 2)
        : baseInterval;
  }

  void _scheduleNextUpdate() {
    _locationTimer?.cancel();
    final interval = _getUpdateInterval(_lastLocationState);

    _locationTimer = Timer(interval, () {
      _updateLocation();
      _scheduleNextUpdate();
    });
  }

  void toggleManualPowerSaving(bool value) {
    if (_lastLocationState == null) return;

    _locationTimer?.cancel();
    final previousState = _lastLocationState!;
    emit(ToggleManualPowerSavingLoading(previousState));
    _lastLocationState = UpdateLocationSuccess(
      distance: previousState.distance,
      bearing: previousState.bearing,
      powerMode: previousState.powerMode,
      classification: previousState.classification,
      readings: previousState.readings,
      isSimulationActive: previousState.isSimulationActive,
      simulationMode: previousState.simulationMode,
      manualPowerSaving: value,
      lastUpdate: previousState.lastUpdate,
    );
    _updateLocation();
    _scheduleNextUpdate();
  }

  void setSimulationMode(LocationMode mode) {
    _locationTimer?.cancel();
    _locationHistory.clear();
    final previousState = _lastLocationState;

    if (previousState != null) {
      emit(SetSimulationModeLoading(previousState: previousState));
      _lastLocationState = UpdateLocationSuccess(
        distance: previousState.distance,
        bearing: previousState.bearing,
        powerMode: previousState.powerMode,
        classification: previousState.classification,
        readings: previousState.readings,
        isSimulationActive: true,
        simulationMode: mode,
        manualPowerSaving: previousState.manualPowerSaving,
        lastUpdate: previousState.lastUpdate,
      );
      _updateLocation();
      _scheduleNextUpdate();
    } else {
      emit(const SetSimulationModeLoading());
      _updateLocation();
      _scheduleNextUpdate();
    }
  }

  void stopSimulation() {
    if (_lastLocationState == null) return;

    _locationTimer?.cancel();
    _locationHistory.clear();
    _boostStartTime = null;
    final previousState = _lastLocationState!;

    emit(StopSimulationLoading(previousState));
    _lastLocationState = UpdateLocationSuccess(
      distance: previousState.distance,
      bearing: previousState.bearing,
      powerMode: previousState.powerMode,
      classification: previousState.classification,
      readings: previousState.readings,
      isSimulationActive: false,
      simulationMode: null,
      manualPowerSaving: previousState.manualPowerSaving,
      lastUpdate: previousState.lastUpdate,
    );
    Future.microtask(() {
      if (!isClosed) {
        _checkPermissionsAndStart();
      }
    });
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    return super.close();
  }
}
