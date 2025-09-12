import 'package:dartz/dartz.dart';
import 'package:hop_eir/core/errors/failures.dart';
import 'package:hop_eir/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  });
  Future<User> createProfile({
    required String email,
    required String password,
    required String number,
    required String lastname,
    required String firstname,
  });
  Future<User?> getProfile({required String email});
  Future<User?> getProfileByUserId({required String userId});
  Future<Either<Failure, void>> logout();
}
