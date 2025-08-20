class RideRequest {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String status;
  final String? requestedAt;

  RideRequest({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.status,
    this.requestedAt,
  });

  factory RideRequest.initial() => RideRequest(
    id: '',
    rideId: '',
    passengerId: '',
    passengerName: '',
    status: 'pending',
    requestedAt: null,
  );

  /// ✅ Safe parser for WebSocket or REST API map
  factory RideRequest.fromMap(Map<String, dynamic> map) {
    final hasFromUser =
        map.containsKey('from_user') && map['from_user'] != null;
    final fromUser = map['from_user'];

    return RideRequest(
      id: (hasFromUser ? map['request_id'] : map['id'])?.toString() ?? '',
      rideId: map['ride_id']?.toString() ?? '',
      passengerId:
          hasFromUser
              ? fromUser['id']?.toString() ?? ''
              : map['passenger_id']?.toString() ?? '',
      passengerName:
          hasFromUser
              ? fromUser['name']?.toString() ?? 'Unknown'
              : map['passenger_name']?.toString() ?? 'Unknown',
      status: map['request_status']?.toString() ?? 'pending',
      requestedAt: map['requested_at']?.toString(),
    );
  }

  RideRequest copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? passengerName,
    String? status,
    String? requestedAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ride_id': rideId,
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'status': status,
      'requested_at': requestedAt,
    };
  }

  @override
  String toString() {
    return 'RideRequest(id: $id, rideId: $rideId, passengerName: $passengerName, status: $status, requestedAt: $requestedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RideRequest &&
        other.id == id &&
        other.rideId == rideId &&
        other.passengerId == passengerId;
  }

  @override
  int get hashCode => id.hashCode ^ rideId.hashCode ^ passengerId.hashCode;
}
