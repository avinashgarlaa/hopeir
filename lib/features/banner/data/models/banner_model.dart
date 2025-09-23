import 'package:hop_eir/features/banner/domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  BannerModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    required super.targetUrl,
    required super.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      targetUrl: json['target_url'],
      isActive: json['is_active'],
    );
  }
}
