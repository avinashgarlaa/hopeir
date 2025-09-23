import 'dart:convert';

import 'package:hop_eir/features/banner/data/models/banner_model.dart';
import 'package:hop_eir/features/banner/domain/entities/banner_entity.dart';
import 'package:hop_eir/features/banner/domain/repositories/banner_repository.dart';
import 'package:http/http.dart' as http;

class BannerRepositoryImpl implements BannerRepository {
  final String apiUrl;

  BannerRepositoryImpl({required this.apiUrl});

  @override
  Future<BannerEntity?> fetchActiveBanner() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final activeBanner =
            data.firstWhere((b) => b['is_active'] == true, orElse: () => null);
        if (activeBanner != null) return BannerModel.fromJson(activeBanner);
      }
    }
    return null;
  }
}
