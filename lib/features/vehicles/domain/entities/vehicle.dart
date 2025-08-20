class Vehicle {
  final int? id;
  final String user;
  final String vehicleType;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleColor;
  final String vehicleLicensePlate;
  final String vehicleEngineType;

  Vehicle({
    this.id,
    required this.user,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.vehicleLicensePlate,
    required this.vehicleEngineType,
  });
}
