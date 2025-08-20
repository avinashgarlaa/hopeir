import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/rides/data/repositories/ride_repository_impl.dart';
import 'package:hop_eir/features/rides/domain/repositories/ride_repository.dart';
import 'package:hop_eir/features/rides/presentation/providers/ride_remote_datasource_provider.dart';

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final remoteDatasource = ref.read(rideRemoteDatasourceProvider);
  return RideRepositoryImpl(remoteDatasource);
});
