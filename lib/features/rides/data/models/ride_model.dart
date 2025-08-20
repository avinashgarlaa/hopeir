import 'package:hop_eir/features/rides/domain/entities/ride.dart';

class RideModel extends Ride {
  RideModel({
    required super.id,
    required super.user,
    required super.vehicle,
    required super.startLocation,
    required super.endLocation,
    required super.distance,
    required super.seats,
    required super.status,
    required super.startTime,
    required super.endTime,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as int,
      user: json['user'],
      vehicle: json['vehicle'] as int,
      startLocation: json['start_location'] as int,
      endLocation: json['end_location'] as int,
      distance: (json['distance']).toDouble(),
      seats: json['seats'] as int,
      status: json['status'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'vehicle': vehicle,
      'start_location': startLocation,
      'end_location': endLocation,
      'distance': distance,
      'seats': seats,
      'status': status,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }
}
