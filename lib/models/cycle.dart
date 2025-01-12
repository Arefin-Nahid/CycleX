class Cycle {
  final String id;
  final String model;
  final double hourlyRate;
  final CycleLocation location;

  Cycle({
    required this.id,
    required this.model,
    required this.hourlyRate,
    required this.location,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] ?? '',
      model: json['model'] ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      location: CycleLocation(
        latitude: (json['location']['lat'] ?? 0.0).toDouble(),
        longitude: (json['location']['lng'] ?? 0.0).toDouble(),
      ),
    );
  }
}

class CycleLocation {
  final double latitude;
  final double longitude;

  CycleLocation({
    required this.latitude,
    required this.longitude,
  });
} 