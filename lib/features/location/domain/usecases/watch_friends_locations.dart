import '../entities/location.dart';
import '../repositories/location_repository.dart';

class WatchFriendsLocations {
  final LocationRepository repository;

  WatchFriendsLocations(this.repository);

  Stream<List<UserLocation>> call(String userId) {
    return repository.watchFriendsLocations(userId);
  }
}
