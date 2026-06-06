import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:turf/core/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getPositionStream();
});
