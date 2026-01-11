class RideRequest {
  final String id;
  final int rideId;
  final String passengerId;
  final String passengerName;
  final String driverId;
  final String status;
  final String? requestedAt;

  RideRequest({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.driverId,
    required this.status,
    this.requestedAt,
  });

  factory RideRequest.initial() => RideRequest(
        id: '',
        rideId: 0,
        passengerId: '',
        passengerName: '',
        driverId: '',
        status: 'pending',
        requestedAt: null,
      );

  // ======================================================
  // ✅ BACKEND SAFE PARSER
  // ======================================================
  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id']?.toString() ?? map['request_id']?.toString() ?? '',
      rideId: map['ride_id'],
      passengerId: map['from_user__user_id']?.toString() ??
          map['passenger_id']?.toString() ??
          '',
      passengerName: map['from_user__first_name']?.toString() ??
          map['passenger_name']?.toString() ??
          'Unknown',
      driverId: map['ride__user__user_id']?.toString() ??
          map['driver_id']?.toString() ??
          '',
      status: map['request_status']?.toString() ??
          map['status']?.toString() ??
          'pending',
      requestedAt: map['requested_at']?.toString(),
    );
  }

  // ======================================================
  // COPY
  // ======================================================
  RideRequest copyWith({
    String? id,
    int? rideId,
    String? passengerId,
    String? passengerName,
    String? driverId,
    String? status,
    String? requestedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  // ======================================================
  // SERIALIZE (OPTIONAL)
  // ======================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ride_id': rideId,
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'driver_id': driverId,
      'status': status,
      'requested_at': requestedAt,
    };
  }

  // ======================================================
  // HELPERS
  // ======================================================
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isRejected => status.toLowerCase() == 'rejected';

  @override
  String toString() {
    return 'RideRequest(id: $id, rideId: $rideId, passengerName: $passengerName, driverId: $driverId, status: $status, requestedAt: $requestedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RideRequest &&
        other.id == id &&
        other.rideId == rideId &&
        other.passengerId == passengerId &&
        other.driverId == driverId;
  }

  @override
  int get hashCode =>
      id.hashCode ^ rideId.hashCode ^ passengerId.hashCode ^ driverId.hashCode;
}
