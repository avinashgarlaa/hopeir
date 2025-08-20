import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<Map<String, dynamic>> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}
