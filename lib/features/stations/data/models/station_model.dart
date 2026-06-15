import '../../domain/entities/station.dart';

class StationModel extends Station {
  StationModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.address,
    super.sector,
    required super.city,
    required super.country,
    super.postalCode,
    super.landmark,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] ?? '',
      sector: json['sector'],
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postal_code'],
      landmark: json['landmark'],
    );
  }
}
