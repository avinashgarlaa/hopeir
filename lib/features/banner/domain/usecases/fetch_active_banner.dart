import 'package:hop_eir/features/banner/domain/entities/banner_entity.dart';
import 'package:hop_eir/features/banner/domain/repositories/banner_repository.dart';

class FetchActiveBanner {
  final BannerRepository repository;

  FetchActiveBanner(this.repository);

  Future<BannerEntity?> call() async {
    return await repository.fetchActiveBanner();
  }
}
