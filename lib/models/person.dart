class Person {
  final String id;
  final String fullName;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final int batteryLevel;
  final bool isCharging;
  final int timestampMs;

  Person({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.batteryLevel,
    required this.isCharging,
    required this.timestampMs,
  });
}
