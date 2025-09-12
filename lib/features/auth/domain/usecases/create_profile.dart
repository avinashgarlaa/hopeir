import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class CreateProfile {
  final AuthRepository repository;

  CreateProfile(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String number,
    required String lastname,
    required String firstname,
  }) {
    return repository.createProfile(
      email: email,
      password: password,
      number: number,
      lastname: lastname,
      firstname: firstname,
    );
  }
}
