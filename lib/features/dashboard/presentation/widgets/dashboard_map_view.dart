import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/tank_data_model.dart';


class DashboardMapView extends StatefulWidget {
  const DashboardMapView({
    super.key,
    required this.tanksData,
    this.height = 600,
    this.initialPosition = const LatLng(11.0168, 76.9558),
    this.initialZoom = 12,
    this.showMyLocation = true,
    this.showZoomControls = true,
    this.onMapCreated,
    this.onMarkerTapped,
    this.onMapTapped,
  });

  final List<TankDataModel> tanksData;
  final double height;
  final LatLng initialPosition;
  final double initialZoom;
  final bool showMyLocation;
  final bool showZoomControls;
  final Function(GoogleMapController)? onMapCreated;
  final Function(Marker)? onMarkerTapped;
  final Function(LatLng)? onMapTapped;

  @override
  State<DashboardMapView> createState() => _DashboardMapViewState();
}

class _DashboardMapViewState extends State<DashboardMapView> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(DashboardMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tanksData != widget.tanksData) {
      _buildMarkers();
    }
  }

  void _buildMarkers() {
    _markers.clear();
    for (var tank in widget.tanksData) {
      if (tank.latitude != 0.0 && tank.longitude != 0.0) {
        _markers.add(
          Marker(
            markerId: MarkerId("${tank.id}"),
            position: LatLng(tank.latitude, tank.longitude),
            infoWindow: InfoWindow(
              title: tank.tankName,
              snippet: 'Level: ${tank.level.toStringAsFixed(1)}% | Status: ${tank.status}',
            ),
            icon: _getMarkerIcon(tank),
            onTap: () {
              if (widget.onMarkerTapped != null) {
                widget.onMarkerTapped!(_markers.firstWhere(
                      (m) => m.markerId.value == tank.id,
                ));
              }
            },
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(TankDataModel tank) {
    // Return different marker colors based on status/level
    // This is a placeholder - you'll need to implement actual marker icons
    return BitmapDescriptor.defaultMarker;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition,
            zoom: widget.initialZoom,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
          markers: _markers,
          myLocationEnabled: widget.showMyLocation,
          zoomControlsEnabled: widget.showZoomControls,
          onTap: widget.onMapTapped,
        ),
      ),
    );
  }

  Future<void> animateToLocation(LatLng position, {double zoom = 15}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: zoom),
        ),
      );
    }
  }

  Future<void> animateToTank(String tankId) async {
    final tank = widget.tanksData.firstWhere(
          (t) => t.id == tankId,
      orElse: () => null as TankDataModel,
    );

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(tank.latitude, tank.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }
}