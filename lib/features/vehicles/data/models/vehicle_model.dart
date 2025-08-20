import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  VehicleModel({
    super.id,
    required super.user,
    required super.vehicleType,
    required super.vehicleModel,
    required super.vehicleYear,
    required super.vehicleColor,
    required super.vehicleLicensePlate,
    required super.vehicleEngineType,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json["id"],
    user: json["user"],
    vehicleType: json["vehicle_type"],
    vehicleModel: json["vehicle_model"],
    vehicleYear: json["vehicle_year"],
    vehicleColor: json["vehicle_color"],
    vehicleLicensePlate: json["vehicle_license_plate"],
    vehicleEngineType: json["vehicle_engine_type"],
  );

  Map<String, dynamic> toJson() => {
    "user": user,
    "vehicle_type": vehicleType,
    "vehicle_model": vehicleModel,
    "vehicle_year": vehicleYear,
    "vehicle_color": vehicleColor,
    "vehicle_license_plate": vehicleLicensePlate,
    "vehicle_engine_type": vehicleEngineType,
  };
}
