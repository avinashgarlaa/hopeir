import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/domain/repositories/vehicle_repository.dart';

class GetVehicleById {
  final VehicleRepository repository;

  GetVehicleById(this.repository);

  Future<Vehicle> call(int vehicleId) {
    return repository.getVehicleById(vehicleId);
  }
}
