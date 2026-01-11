import '../../domain/entities/ride_request.dart';

class RideRequestModel {
  final String id;
  final int rideId;
  final String passengerId;
  final String passengerName;
  final String driverId;
  final String status;
  final String? requestedAt;

  RideRequestModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.driverId,
    required this.status,
    this.requestedAt,
  });

  // ======================================================
  // ✅ BACKEND-SAFE PARSER (REST + WS)
  // ======================================================
  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['id']?.toString() ?? json['request_id']?.toString() ?? '',
      rideId: json['ride_id'],
      passengerId: json['from_user__user_id']?.toString() ??
          json['passenger_id']?.toString() ??
          '',
      passengerName: json['from_user__first_name']?.toString() ??
          json['passenger_name']?.toString() ??
          'Unknown',
      driverId: json['ride__user__user_id']?.toString() ??
          json['driver_id']?.toString() ??
          '',
      status: json['request_status']?.toString() ??
          json['status']?.toString() ??
          'pending',
      requestedAt: json['requested_at']?.toString(),
    );
  }

  // ======================================================
  // TO DOMAIN ENTITY
  // ======================================================
  RideRequest toEntity() {
    return RideRequest(
      id: id,
      rideId: rideId,
      passengerId: passengerId,
      passengerName: passengerName,
      driverId: driverId,
      status: status,
      requestedAt: requestedAt,
    );
  }
}
