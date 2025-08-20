import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/presentation/providers/dio_provider.dart';
import 'package:hop_eir/features/rides/data/datasources/ride_remote_datasource.dart';
import 'package:hop_eir/features/rides/data/datasources/ride_remote_datasource_impl.dart';

final rideRemoteDatasourceProvider = Provider<RideRemoteDatasource>((ref) {
  final dio = ref.read(dioProvider);
  return RideRemoteDatasourceImpl(dio);
});
