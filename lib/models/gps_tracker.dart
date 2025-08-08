class DemoGPSTracker {
  final String trackerId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;
  final double battery;
  final double signalStrength;
  final double accuracy;

  DemoGPSTracker({
    required this.trackerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0.0,
    this.battery = 100.0,
    this.signalStrength = -100.0,
    this.accuracy = 5.0,
  });

  factory DemoGPSTracker.fromMap(String trackerId, Map<String, dynamic> data) {
    return DemoGPSTracker(
      trackerId: trackerId,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      speed: (data['speed'] ?? 0.0).toDouble(),
      battery: (data['battery'] ?? 100.0).toDouble(),
      signalStrength: (data['signal_strength'] ?? -100.0).toDouble(),
      accuracy: (data['accuracy'] ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speed': speed,
      'battery': battery,
      'signal_strength': signalStrength,
      'accuracy': accuracy,
    };
  }

  DemoGPSTracker copyWith({
    String? trackerId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? battery,
    double? signalStrength,
    double? accuracy,
  }) {
    return DemoGPSTracker(
      trackerId: trackerId ?? this.trackerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      battery: battery ?? this.battery,
      signalStrength: signalStrength ?? this.signalStrength,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  String toString() {
    return 'DemoGPSTracker(trackerId: $trackerId, latitude: $latitude, longitude: $longitude, timestamp: $timestamp, speed: $speed, battery: $battery, signalStrength: $signalStrength, accuracy: $accuracy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DemoGPSTracker &&
        other.trackerId == trackerId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp &&
        other.speed == speed &&
        other.battery == battery &&
        other.signalStrength == signalStrength &&
        other.accuracy == accuracy;
  }

  @override
  int get hashCode {
    return trackerId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        timestamp.hashCode ^
        speed.hashCode ^
        battery.hashCode ^
        signalStrength.hashCode ^
        accuracy.hashCode;
  }
}
