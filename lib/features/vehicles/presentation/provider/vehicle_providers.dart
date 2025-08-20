import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/presentation/providers/dio_provider.dart';
import 'package:hop_eir/features/vehicles/data/datasources/vehicle_remote_datasource.dart';
import 'package:hop_eir/features/vehicles/data/datasources/vehicle_remote_datasource_impl.dart';
import 'package:hop_eir/features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:hop_eir/features/vehicles/domain/usecases/get_vehicle_by_id.dart';
import 'package:hop_eir/features/vehicles/domain/usecases/get_vehicle_by_userid.dart';
import 'package:hop_eir/features/vehicles/domain/usecases/post_vehicle.dart';
import 'package:hop_eir/features/vehicles/presentation/controllers/vehicle_controller.dart';

final vehicleRemoteDatasourceProvider = Provider<VehicleRemoteDataSource>((
  ref,
) {
  final dio = ref.read(dioProvider);
  return VehicleRemoteDataSourceImpl(dio: dio);
});
// Provide the repository
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final remoteDataSource = ref.read(vehicleRemoteDatasourceProvider);
  return VehicleRepositoryImpl(remoteDataSource: remoteDataSource);
});

final vehicleControllerProvider =
    StateNotifierProvider<VehicleController, VehicleControllerState>((ref) {
      final repository = ref.watch(vehicleRepositoryProvider);
      return VehicleController(repository);
    });

final postVehicleUseCaseProvider = Provider<PostVehicle>((ref) {
  final repository = ref.read(vehicleRepositoryProvider);
  return PostVehicle(repository);
});

final getVehicleByUserIdUseCaseProvider = Provider<GetVehicleByUserid>((ref) {
  final repository = ref.read(vehicleRepositoryProvider);
  return GetVehicleByUserid(repository);
});

final getVehicleByIdUseCaseProvider = Provider<GetVehicleById>((ref) {
  final repository = ref.read(vehicleRepositoryProvider);
  return GetVehicleById(repository);
});

final vehicleByIdProvider = FutureProvider.family((ref, int vehicleId) async {
  final getVehicleById = ref.read(getVehicleByIdUseCaseProvider);
  final vehicle = await getVehicleById.call(vehicleId);
  return vehicle;
});

final fetchVehicleByIdProvider = FutureProvider.family<Vehicle?, int>((
  ref,
  vehicleId,
) async {
  final controller = ref.read(vehicleControllerProvider.notifier);
  return await controller.fetchVehicleById(vehicleId); // returns Vehicle?
});
