import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/vehicles/domain/entities/vehicle.dart';
import 'package:hop_eir/features/vehicles/domain/repositories/vehicle_repository.dart';

class VehicleControllerState {
  final Vehicle? vehicle;
  final bool isLoading;
  final String? error;

  const VehicleControllerState({
    this.vehicle,
    this.isLoading = false,
    this.error,
  });

  VehicleControllerState copyWith({
    Vehicle? vehicle,
    bool? isLoading,
    String? error,
  }) {
    return VehicleControllerState(
      vehicle: vehicle ?? this.vehicle,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Returns the initial/default state
  factory VehicleControllerState.initial() {
    return const VehicleControllerState();
  }
}

class VehicleController extends StateNotifier<VehicleControllerState> {
  final VehicleRepository repository;

  VehicleController(this.repository) : super(const VehicleControllerState());

  Future<void> fetchVehicleByUserId(String userId) async {
    state = state.copyWith(isLoading: true, error: null, vehicle: null);
    try {
      final vehicle = await repository.getVehicleByUserId(userId);
      state = state.copyWith(vehicle: vehicle, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        vehicle: null,
      );
    }
  }

  void reset() {
    state = VehicleControllerState.initial();
  }

  Future<Vehicle?> fetchVehicleById(int id) async {
    final vehicle = await repository.getVehicleById(id);
    return vehicle;
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newVehicle = await repository.postVehicle(vehicle);
      state = state.copyWith(vehicle: newVehicle, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Vehicle?> getVehicleForUser(String userId) async {
    final vehicle = await repository.getVehicleByUserId(userId);
    return vehicle;
  }

  void clear() {
    state = const VehicleControllerState();
  }
}
