import 'package:hop_eir/features/vehicles/data/datasources/vehicle_remote_datasource.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Vehicle> postVehicle(Vehicle vehicle) async {
    final model = VehicleModel(
      user: vehicle.user,
      vehicleType: vehicle.vehicleType,
      vehicleModel: vehicle.vehicleModel,
      vehicleYear: vehicle.vehicleYear,
      vehicleColor: vehicle.vehicleColor,
      vehicleLicensePlate: vehicle.vehicleLicensePlate,
      vehicleEngineType: vehicle.vehicleEngineType,
    );
    return await remoteDataSource.postVehicle(model);
  }

  @override
  Future<Vehicle> getVehicleById(int vehicleId) async {
    return await remoteDataSource.getVehicleById(vehicleId);
  }

  @override
  Future<Vehicle> getVehicleByUserId(String userId) async {
    return await remoteDataSource.getVehicleByUserid(userId);
  }
}
