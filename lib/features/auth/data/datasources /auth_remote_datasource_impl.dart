// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hop_eir/features/auth/data/datasources%20/auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl extends AuthRemoteDatasource {
  final Dio dio;

  AuthRemoteDatasourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> createProfile({
    required String email,
    required String password,
    required String number,
    required String firstname,
    required String lastname,
  }) async {
    try {
      final data = {
        "phone_number": number,
        "username": number,
        "first_name": firstname,
        "last_name": lastname,
        "bio": "This bio has been completely updated.",
        "date_of_birth": "1996-09-16",
        "profile_picture":
            "https://placehold.co/400x400/CCC/31343C?text=Updated",
      };
      print("Sending data: $data");

      final response = await dio.patch(
        'https://hopeir.onrender.com/profile/$email/',
        data: data,
      );

      print("Status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to create profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Create profile failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      "formFields": [
        {"id": "email", "value": email},
        {"id": "password", "value": password},
      ],
    });
    final response = await dio.post(
      'https://hopeir.onrender.com/auth/signin',
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ),
    );
    return response.data;
  }

  @override
  Future<void> logout() async {
    await dio.post('https://hopeir.onrender.com/auth/logout');
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      "formFields": [
        {"id": "email", "value": email},
        {"id": "password", "value": password},
      ],
    });
    final response = await dio.post(
      'https://hopeir.onrender.com/auth/signup',
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ),
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>?> getProfile({required String email}) async {
    try {
      final response = await dio.get(
        'https://hopeir.onrender.com/profile/$email',
      );

      // If backend returns an error as JSON with a "detail" key:
      if (response.data is Map && response.data['detail'] != null) {
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      print("Dio error: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Unknown error in getProfile: $e");
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUserId({
    required String userId,
  }) async {
    try {
      final response = await dio.get(
        'https://hopeir.onrender.com/profiles/$userId',
      );

      // If backend returns an error as JSON with a "detail" key:
      if (response.data is Map && response.data['detail'] != null) {
        print("No profile found: ${response.data['detail']}");
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      print("Dio error: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Unknown error in getProfile: $e");
      return null;
    }
  }
}
