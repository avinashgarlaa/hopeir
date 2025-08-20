import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/data/datasources%20/auth_remote_datasource.dart';
import 'package:hop_eir/features/auth/data/datasources%20/auth_remote_datasource_impl.dart';
import 'package:hop_eir/features/auth/presentation/providers/dio_provider.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRemoteDatasourceImpl(dio);
});
