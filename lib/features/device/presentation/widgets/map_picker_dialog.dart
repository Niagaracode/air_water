import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerDialog extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialLocation;

  const MapPickerDialog({super.key, this.initialAddress, this.initialLocation});

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (_selectedLocation != null) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      try {
        final locations = await locationFromAddress(widget.initialAddress!);
        if (locations.isNotEmpty) {
          setState(() {
            _selectedLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
        // Fallback to a default location if geocoding fails
      }
    }

    // Default to a central location (e.g., India or something sensible)
    setState(() {
      _selectedLocation = const LatLng(20.5937, 78.9629);
      _isLoading = false;
    });
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Device Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 15,
                          ),
                          onTap: _onMapTap,
                          markers: _selectedLocation != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('selected'),
                                    position: _selectedLocation!,
                                  ),
                                }
                              : {},
                        ),
                        if (widget.initialAddress != null)
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Plant Address: ${widget.initialAddress}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedLocation == null
                        ? null
                        : () => Navigator.pop(context, _selectedLocation),
                    child: const Text('CONFIRM LOCATION'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
