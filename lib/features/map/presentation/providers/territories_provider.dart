import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:turf/features/map/data/territory_repository.dart';
import 'package:turf/features/map/domain/models/territory.dart';

final territoryRepositoryProvider = Provider<TerritoryRepository>((ref) {
  return TerritoryRepository();
});

class MapBoundsNotifier extends Notifier<LatLngBounds?> {
  @override
  LatLngBounds? build() => null;

  void updateBounds(LatLngBounds bounds) {
    state = bounds;
  }
}

final mapBoundsProvider = NotifierProvider<MapBoundsNotifier, LatLngBounds?>(() {
  return MapBoundsNotifier();
});

final territoriesProvider = StreamProvider<List<Territory>>((ref) {
  final bounds = ref.watch(mapBoundsProvider);
  if (bounds == null) return Stream.value([]);

  final repository = ref.watch(territoryRepositoryProvider);
  return repository.streamTerritoriesInBounds(
    minLat: bounds.south,
    maxLat: bounds.north,
    minLng: bounds.west,
    maxLng: bounds.east,
  );
});
