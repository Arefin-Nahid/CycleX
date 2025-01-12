import 'package:CycleX/models/cycle.dart';

class Rental {
  final String id;
  final Cycle cycle;
  final String renterUID;
  final DateTime startTime;
  final int duration;
  final double totalCost;
  final String status;
  final DateTime createdAt;

  Rental({
    required this.id,
    required this.cycle,
    required this.renterUID,
    required this.startTime,
    required this.duration,
    required this.totalCost,
    required this.status,
    required this.createdAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['_id'],
      cycle: Cycle.fromJson(json['cycleId']),
      renterUID: json['renterUID'],
      startTime: DateTime.parse(json['startTime']),
      duration: json['duration'],
      totalCost: json['totalCost'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 