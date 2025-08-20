import '../../domain/entities/ride_request.dart';

class RideRequestModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String status;
  final String? requestedAt;

  RideRequestModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.status,
    this.requestedAt,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    final bool hasFromUser = json.containsKey('from_user');

    final Map<String, dynamic> fromUser =
        hasFromUser ? json['from_user'] ?? {} : {};

    return RideRequestModel(
      id: (json['request_id'] ?? json['id']).toString(),
      rideId: json['ride_id'].toString(),
      passengerId:
          hasFromUser
              ? (fromUser['id'] ?? '').toString()
              : (json['passenger_id'] ?? '').toString(),
      passengerName:
          hasFromUser
              ? (fromUser['name'] ?? '')
              : (json['passenger_name'] ?? ''),
      status: json['request_status'] ?? '',
      requestedAt: json['requested_at'],
    );
  }

  RideRequest toEntity() {
    return RideRequest(
      id: id,
      rideId: rideId,
      passengerId: passengerId,
      passengerName: passengerName,
      status: status,
      requestedAt: requestedAt,
    );
  }
}
