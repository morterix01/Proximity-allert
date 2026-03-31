class MonitoredLocation {
  final String name;
  final double lat;
  final double lon;
  final int radiusMeters;

  MonitoredLocation({
    required this.name,
    required this.lat,
    required this.lon,
    required this.radiusMeters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': lat,
    'lon': lon,
    'radius_m': radiusMeters,
  };

  factory MonitoredLocation.fromJson(Map<String, dynamic> json) => MonitoredLocation(
    name: json['name'],
    lat: json['lat'].toDouble(),
    lon: json['lon'].toDouble(),
    radiusMeters: json['radius_m'] ?? 100,
  );
}
