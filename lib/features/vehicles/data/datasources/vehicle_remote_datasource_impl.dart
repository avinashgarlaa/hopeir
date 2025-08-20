// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:hop_eir/features/vehicles/data/datasources/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final Dio dio;

  VehicleRemoteDataSourceImpl({required this.dio});

  @override
  Future<VehicleModel> postVehicle(VehicleModel vehicle) async {
    try {
      final response = await dio.post(
        'https://hopeir.onrender.com/vehicles/',
        data: vehicle.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VehicleModel.fromJson(response.data);
      } else {
        throw Exception('Failed to post vehicle');
      }
    } catch (e) {
      throw Exception('Error posting vehicle: $e');
    }
  }

  @override
  Future<VehicleModel> getVehicleById(int vehicleId) async {
    try {
      final response = await dio.get(
        'https://hopeir.onrender.com/vehicles/?vehicle_id=$vehicleId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;
        print(dataList[0]);
        if (dataList.isNotEmpty) {
          return VehicleModel.fromJson(dataList[0]);
        } else {
          throw Exception('No vehicles found for user');
        }
      } else {
        throw Exception('Failed to get vehicles for user');
      }
    } catch (e) {
      throw Exception('Error getting vehicle by ID: $e');
    }
  }

  @override
  Future<VehicleModel> getVehicleByUserid(String userId) async {
    try {
      final response = await dio.get(
        'https://hopeir.onrender.com/vehicles/?user_id=$userId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;
        print(dataList[0]);
        if (dataList.isNotEmpty) {
          return VehicleModel.fromJson(dataList[0]);
        } else {
          throw Exception('No vehicles found for user');
        }
      } else {
        throw Exception('Failed to get vehicles for user');
      }
    } catch (e) {
      throw Exception('Error getting vehicles by user: $e');
    }
  }
}
