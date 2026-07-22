import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/training/imported_workout.dart';

/// The GPS route drawn as a polyline over a native Apple Map, fit to the run's
/// bounds. Gestures are enabled only when [interactive] (i.e. expanded), so the
/// collapsed thumbnail lets the surrounding list scroll / tap-to-expand.
class RouteMap extends StatefulWidget {
  const RouteMap({super.key, required this.points, this.interactive = false});

  final List<RoutePoint> points;
  final bool interactive;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  AppleMapController? _controller;

  ({LatLng center, LatLngBounds bounds}) _geometry() {
    var minLat = widget.points.first.lat, maxLat = widget.points.first.lat;
    var minLng = widget.points.first.lng, maxLng = widget.points.first.lng;
    for (final p in widget.points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    return (
      center: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
      bounds: LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
    );
  }

  void _fit() {
    if (_controller == null || widget.points.length < 2) return;
    _controller!.moveCamera(CameraUpdate.newLatLngBounds(_geometry().bounds, 24));
  }

  @override
  void didUpdateWidget(RouteMap old) {
    super.didUpdateWidget(old);
    // Re-fit after the container animates between collapsed/expanded.
    if (old.interactive != widget.interactive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) return const SizedBox.shrink();
    final geo = _geometry();
    final pts = widget.points.map((p) => LatLng(p.lat, p.lng)).toList();

    return AppleMap(
      initialCameraPosition: CameraPosition(target: geo.center, zoom: 13),
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: pts,
          color: const Color(0xFF0E9F6E),
          width: 4,
        ),
      },
      onMapCreated: (controller) {
        _controller = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
      },
      zoomGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: false,
      pitchGesturesEnabled: false,
      myLocationEnabled: false,
    );
  }
}
