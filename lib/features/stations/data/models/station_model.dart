import '../../domain/entities/station.dart';

class StationModel extends Station {
  // ignore: use_super_parameters
  StationModel({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required String address,
    required String sector,
    required String city,
    required String country,
    required String postalCode,
    required String landmark,
  }) : super(
         id: id,
         name: name,
         latitude: latitude,
         longitude: longitude,
         address: address,
         sector: sector,
         city: city,
         country: country,
         postalCode: postalCode,
         landmark: landmark,
       );

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      sector: json['sector'],
      city: json['city'],
      country: json['country'],
      postalCode: json['postal_code'],
      landmark: json['landmark'],
    );
  }
}
