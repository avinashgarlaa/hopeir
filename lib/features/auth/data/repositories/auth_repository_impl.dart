// ignore_for_file: avoid_print

import 'package:dartz/dartz.dart';
import 'package:hop_eir/core/errors/failures.dart';
import 'package:hop_eir/features/auth/data/datasources%20/auth_remote_datasource.dart';
import 'package:hop_eir/features/auth/data/models/user_model.dart';
import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Future<User> createProfile({
    required String email,
    required String password,
    required String number,
    required String firstname,
    required String lastname,
  }) async {
    final response = await remoteDatasource.createProfile(
      number: number,
      email: email,
      password: password,
      firstname: firstname,
      lastname: lastname,
    );

    return UserModel.fromProfileJson(response);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await remoteDatasource.login(
      email: email,
      password: password,
    );

    return response;
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final response = await remoteDatasource.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  @override
  Future<User?> getProfile({required String email}) async {
    final response = await remoteDatasource.getProfile(email: email);

    if (response == null) {
      return null;
    }

    try {
      return UserModel.fromProfileJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDatasource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<User?> getProfileByUserId({required String userId}) async {
    final response = await remoteDatasource.getProfileByUserId(userId: userId);

    if (response == null) {
      print('❌ Invalid profile response: $response');
      return null;
    }

    try {
      return UserModel.fromProfileJson(response);
    } catch (e) {
      print('Error parsing profile JSON: $e');
      return null;
    }
  }
}
