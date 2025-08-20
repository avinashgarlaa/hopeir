import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class GetProfileUsecase {
  final AuthRepository repository;

  GetProfileUsecase(this.repository);

  Future<User?> call({required String email}) async {
    return await repository.getProfile(email: email);
  }
}
