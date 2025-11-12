import '../../data/models/location_reading_model.dart';
import '../../domain/enums/location_mode.dart';

enum PowerMode { lowPower, medium, boost }

enum LocationClassification { insideMataf, insideHaram, outsideRange }

abstract class LocationState {
  const LocationState();
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class StartLocationUpdatesLoading extends LocationState {
  const StartLocationUpdatesLoading();
}

class StartLocationUpdatesSuccess extends LocationState {
  const StartLocationUpdatesSuccess();
}

class StartLocationUpdatesError extends LocationState {
  final String message;

  const StartLocationUpdatesError(this.message);
}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied({
    this.message = 'Location permission denied. Please allow location access.',
  });
}

class LocationPermissionPermanentlyDenied extends LocationState {
  final String message;

  const LocationPermissionPermanentlyDenied({
    this.message = 'Location permission permanently denied. Please enable in settings.',
  });
}

class UpdateLocationLoading extends LocationState {
  final UpdateLocationSuccess? previousState;

  const UpdateLocationLoading({this.previousState});
}

class UpdateLocationSuccess extends LocationState {
  final double distance;
  final double bearing;
  final PowerMode powerMode;
  final LocationClassification classification;
  final List<LocationReadingModel> readings;
  final bool isSimulationActive;
  final LocationMode? simulationMode;
  final bool manualPowerSaving;
  final DateTime lastUpdate;

  const UpdateLocationSuccess({
    required this.distance,
    required this.bearing,
    required this.powerMode,
    required this.classification,
    required this.readings,
    this.isSimulationActive = false,
    this.simulationMode,
    this.manualPowerSaving = false,
    required this.lastUpdate,
  });
}

class UpdateLocationError extends LocationState {
  final String message;
  final UpdateLocationSuccess? previousState;

  const UpdateLocationError(this.message, {this.previousState});
}

class ToggleManualPowerSavingLoading extends LocationState {
  final UpdateLocationSuccess previousState;

  const ToggleManualPowerSavingLoading(this.previousState);
}

class ToggleManualPowerSavingSuccess extends LocationState {
  final double distance;
  final double bearing;
  final PowerMode powerMode;
  final LocationClassification classification;
  final List<LocationReadingModel> readings;
  final bool isSimulationActive;
  final LocationMode? simulationMode;
  final bool manualPowerSaving;
  final DateTime lastUpdate;

  const ToggleManualPowerSavingSuccess({
    required this.distance,
    required this.bearing,
    required this.powerMode,
    required this.classification,
    required this.readings,
    this.isSimulationActive = false,
    this.simulationMode,
    required this.manualPowerSaving,
    required this.lastUpdate,
  });
}

class ToggleManualPowerSavingError extends LocationState {
  final String message;
  final UpdateLocationSuccess? previousState;

  const ToggleManualPowerSavingError(this.message, {this.previousState});
}

class SetSimulationModeLoading extends LocationState {
  final UpdateLocationSuccess? previousState;

  const SetSimulationModeLoading({this.previousState});
}

class SetSimulationModeSuccess extends LocationState {
  final double distance;
  final double bearing;
  final PowerMode powerMode;
  final LocationClassification classification;
  final List<LocationReadingModel> readings;
  final bool isSimulationActive;
  final LocationMode simulationMode;
  final bool manualPowerSaving;
  final DateTime lastUpdate;

  const SetSimulationModeSuccess({
    required this.distance,
    required this.bearing,
    required this.powerMode,
    required this.classification,
    required this.readings,
    required this.isSimulationActive,
    required this.simulationMode,
    required this.manualPowerSaving,
    required this.lastUpdate,
  });
}

class SetSimulationModeError extends LocationState {
  final String message;
  final UpdateLocationSuccess? previousState;

  const SetSimulationModeError(this.message, {this.previousState});
}

class StopSimulationLoading extends LocationState {
  final UpdateLocationSuccess previousState;

  const StopSimulationLoading(this.previousState);
}

class StopSimulationSuccess extends LocationState {
  final double distance;
  final double bearing;
  final PowerMode powerMode;
  final LocationClassification classification;
  final List<LocationReadingModel> readings;
  final bool isSimulationActive;
  final LocationMode? simulationMode;
  final bool manualPowerSaving;
  final DateTime lastUpdate;

  const StopSimulationSuccess({
    required this.distance,
    required this.bearing,
    required this.powerMode,
    required this.classification,
    required this.readings,
    required this.isSimulationActive,
    required this.simulationMode,
    required this.manualPowerSaving,
    required this.lastUpdate,
  });
}

class StopSimulationError extends LocationState {
  final String message;
  final UpdateLocationSuccess? previousState;

  const StopSimulationError(this.message, {this.previousState});
}
