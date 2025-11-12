class LocationReadingModel {
  final double lat;
  final double lon;
  final double accuracy;
  final DateTime timestamp;

  const LocationReadingModel({
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.timestamp,
  });
}
