import 'package:hop_eir/features/auth/domain/entities/user.dart';
import 'package:hop_eir/features/auth/domain/repositories/auth_repository.dart';

class GetProfileById {
  final AuthRepository repository;

  GetProfileById(this.repository);

  Future<User?> call({required String userId}) async {
    return await repository.getProfileByUserId(userId: userId);
  }
}
