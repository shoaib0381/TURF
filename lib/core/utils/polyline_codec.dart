import 'package:latlong2/latlong.dart';

class PolylineCodec {
  static String encode(List<LatLng> points) {
    var output = StringBuffer();
    var lastLat = 0;
    var lastLng = 0;

    for (var point in points) {
      var lat = (point.latitude * 1e5).round();
      var lng = (point.longitude * 1e5).round();

      var dLat = lat - lastLat;
      var dLng = lng - lastLng;

      _encodeValue(output, dLat);
      _encodeValue(output, dLng);

      lastLat = lat;
      lastLng = lng;
    }
    return output.toString();
  }

  static void _encodeValue(StringBuffer output, int value) {
    value = value < 0 ? ~(value << 1) : (value << 1);
    while (value >= 0x20) {
      output.write(String.fromCharCode((0x20 | (value & 0x1f)) + 63));
      value >>= 5;
    }
    output.write(String.fromCharCode(value + 63));
  }

  static List<LatLng> decode(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= len) {
        break;
      }
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
