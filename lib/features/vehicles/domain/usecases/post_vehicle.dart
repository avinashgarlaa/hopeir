import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/domain/repositories/vehicle_repository.dart';

class PostVehicle {
  final VehicleRepository repository;

  PostVehicle(this.repository);

  Future<Vehicle> call(Vehicle vehicle) {
    return repository.postVehicle(vehicle);
  }
}
