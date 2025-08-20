import '../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  Future<VehicleModel> postVehicle(VehicleModel vehicle);
  Future<VehicleModel> getVehicleById(int vehicleId);
  Future<VehicleModel> getVehicleByUserid(String userId);
}
