import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hop_eir/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';
import 'package:hop_eir/features/auth/presentation/providers/auth_remote_datasource_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.read(authRemoteDatasourceProvider);
  return AuthRepositoryImpl(remoteDatasource);
});
