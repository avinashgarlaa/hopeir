import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/domain/repositories/vehicle_repository.dart';

class GetVehicleByUserid {
  final VehicleRepository repository;

  GetVehicleByUserid(this.repository);

  Future<Vehicle> call(String userId) {
    return repository.getVehicleByUserId(userId);
  }
}
