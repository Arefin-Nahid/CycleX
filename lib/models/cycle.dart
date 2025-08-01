class Cycle {
  final String id;
  final String owner;
  final String brand;
  final String model;
  final String condition;
  final double hourlyRate;
  final String description;
  final String location;
  final bool isRented;
  final bool isActive;
  final CycleLocation? coordinates;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cycle({
    required this.id,
    required this.owner,
    required this.brand,
    required this.model,
    required this.condition,
    required this.hourlyRate,
    required this.description,
    required this.location,
    required this.isRented,
    required this.isActive,
    this.coordinates,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['_id'] ?? json['id'] ?? '',
      owner: json['owner'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      condition: json['condition'] ?? 'Good',
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      isRented: json['isRented'] ?? false,
      isActive: json['isActive'] ?? false,
      coordinates: json['coordinates'] != null 
          ? CycleLocation.fromJson(json['coordinates'])
          : null,
      images: json['images'] != null 
          ? List<String>.from(json['images'])
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'owner': owner,
      'brand': brand,
      'model': model,
      'condition': condition,
      'hourlyRate': hourlyRate,
      'description': description,
      'location': location,
      'isRented': isRented,
      'isActive': isActive,
      'coordinates': coordinates?.toJson(),
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to check if cycle is available for rent
  bool get isAvailable => isActive && !isRented;

  // Helper method to get display name
  String get displayName => '$brand $model';

  // Helper method to get formatted price
  String get formattedPrice => '৳${hourlyRate.toStringAsFixed(2)}/hour';
}

class CycleLocation {
  final double latitude;
  final double longitude;

  CycleLocation({
    required this.latitude,
    required this.longitude,
  });

  factory CycleLocation.fromJson(Map<String, dynamic> json) {
    return CycleLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
} 