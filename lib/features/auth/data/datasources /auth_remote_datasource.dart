abstract class AuthRemoteDatasource {
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> createProfile({
    required String number,
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  });

  Future<Map<String, dynamic>?> getProfile({required String email});
  Future<Map<String, dynamic>?> getProfileByUserId({required String userId});
  Future<void> logout();
}
