import 'dart:math';

const double _earthRadiusMeters = 6371000.0;

double _toRadians(double degrees) => degrees * pi / 180.0;
double _toDegrees(double radians) => radians * 180.0 / pi;

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _toRadians(lat1);
  final phi2 = _toRadians(lat2);
  final dPhi = _toRadians(lat2 - lat1);
  final dLambda = _toRadians(lon2 - lon1);

  final a = sin(dPhi / 2) * sin(dPhi / 2) +
      cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return _earthRadiusMeters * c;
}

double bearingBetween(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _toRadians(lat1);
  final phi2 = _toRadians(lat2);
  final lambda1 = _toRadians(lon1);
  final lambda2 = _toRadians(lon2);
  final y = sin(lambda2 - lambda1) * cos(phi2);
  final x = cos(phi1) * sin(phi2) -
      sin(phi1) * cos(phi2) * cos(lambda2 - lambda1);
  final theta = atan2(y, x);
  return (_toDegrees(theta) + 360) % 360;
}

T median<T extends num>(List<T> values) {
  if (values.isEmpty) throw ArgumentError('Cannot calculate median of empty list');
  final sorted = List<T>.from(values)..sort();
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  final a = sorted[n ~/ 2 - 1];
  final b = sorted[n ~/ 2];
  return ((a.toDouble() + b.toDouble()) / 2) as T;
}

Map<String, double> movingMedian(List<Map<String, double>> points) {
  if (points.isEmpty) throw ArgumentError('Cannot calculate moving median of empty points');
  final lats = points.map((p) => p['lat']!).toList();
  final lons = points.map((p) => p['lon']!).toList();
  return {
    'lat': median<double>(lats),
    'lon': median<double>(lons),
  };
}
