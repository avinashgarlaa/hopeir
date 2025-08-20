class Ride {
  final int id;
  final String user;
  final int vehicle;
  final int seats;
  final int startLocation;
  final int endLocation;
  final double distance;
  final String status;
  final DateTime startTime;
  final DateTime endTime;

  Ride({
    required this.seats,
    required this.id,
    required this.user,
    required this.vehicle,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.status,
    required this.startTime,
    required this.endTime,
  });
}
