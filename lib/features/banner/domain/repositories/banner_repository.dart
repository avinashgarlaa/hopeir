import 'package:hop_eir/features/banner/domain/entities/banner_entity.dart';

abstract class BannerRepository {
  Future<BannerEntity?> fetchActiveBanner();
}
