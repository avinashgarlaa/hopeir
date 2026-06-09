// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hop_eir/base_url.dart';
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

      final response = await dio.patch(
        '$baseURL/profile/$email/',
        data: data,
      );


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
      '$baseURL/auth/signin',
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
    await dio.post('$baseURL/auth/logout');
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
      '$baseURL/auth/signup',
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
        '$baseURL/profile/$email',
      );

      // If backend returns an error as JSON with a "detail" key:
      if (response.data is Map && response.data['detail'] != null) {
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUserId({
    required String userId,
  }) async {
    try {
      if (userId.isEmpty) {
        return null;
      }
      final url = '$baseURL/profiles/$userId';

      final response = await dio.get(url);

      // If backend returns an error as JSON with a "detail" key:
      if (response.data is Map && response.data['detail'] != null) {
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }
}
