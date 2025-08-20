// features/stations/presentation/providers/station_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/stations/domain/usecases/get_all_stations.dart';
import 'package:hop_eir/features/stations/domain/usecases/get_station_by_id.dart';
import '../../data/services/station_api_service.dart';

import '../../data/models/station_model.dart';

final stationApiServiceProvider = Provider((ref) => StationApiService());

final allStationsProvider = FutureProvider<List<StationModel>>((ref) async {
  final service = ref.read(stationApiServiceProvider);
  return await GetAllStationsUseCase(service).call();
});

final stationByIdProvider = FutureProvider.family<StationModel, int>((
  ref,
  id,
) async {
  final service = ref.read(stationApiServiceProvider);
  return await GetStationByIdUseCase(service).call(id);
});

final hasUnreadRequestsProvider = StateProvider<bool>((ref) => false);
