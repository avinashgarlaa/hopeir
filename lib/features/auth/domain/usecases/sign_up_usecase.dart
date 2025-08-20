import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class SignUpUsecase {
  final AuthRepository repository;

  SignUpUsecase(this.repository);

  Future<Map<String, dynamic>> call({
    required String email,
    required String password,
  }) {
    return repository.signUp(email: email, password: password);
  }
}
