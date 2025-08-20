import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<Vehicle> postVehicle(Vehicle vehicle);
  Future<Vehicle> getVehicleById(int vehicleId);
  Future<Vehicle> getVehicleByUserId(String userId);
}
