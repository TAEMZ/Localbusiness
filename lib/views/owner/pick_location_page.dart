import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PickLocationPage extends StatefulWidget {
  final LatLng? initialLocation;

  const PickLocationPage({super.key, this.initialLocation});

  @override
  _PickLocationPageState createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  String? _selectedLocationAddress;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _checkPermissions(Permission.location, context);
    if (!mounted) return; // Check if widget is still mounted
    if (widget.initialLocation != null) {
      if (!mounted) return; // Check again before calling setState
      setState(() {
        _selectedLocation = widget.initialLocation!;
        _addMarker(_selectedLocation!);
      });
    } else {
      LatLng currentLocation = await _getCurrentLocation();
      if (!mounted) return; // Check again before calling setState
      setState(() {
        _selectedLocation = currentLocation;
        _addMarker(currentLocation);
      });
    }
    if (_selectedLocation != null) {
      _updateAddress(_selectedLocation!);
    }
  }

  Future<void> _checkPermissions(
      Permission permission, BuildContext context) async {
    if (!await Permission.location.serviceStatus.isEnabled) {
      await Permission.location.request();
    }

    if (await Permission.location.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _updateAddress(LatLng location) async {
    try {
      String address = await _getAddress(location);
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        _selectedLocationAddress = address;
      });
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        _selectedLocationAddress = 'Unable to fetch address';
      });
    }
  }

  Future<String> _getAddress(LatLng location) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=YOUR_GOOGLE_MAPS_API_KEY';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'][0]['formatted_address'];
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await _setMapStyle();
    if (_selectedLocation != null) {
      _mapController!.moveCamera(CameraUpdate.newLatLng(_selectedLocation!));
    }
  }

  Future<void> _setMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    _mapController!.setMapStyle(style);
  }

  void _addMarker(LatLng position) {
    if (!mounted) return; // Check before modifying the state
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
        ),
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.pick_location),
      ),
      body: _selectedLocation == null
          ? const Center(
              child: SpinKitWave(
              color:
                  Colors.black, // Or use Theme.of(context).colorScheme.primary
              size: 50.0,
            ))
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(7.8514, 38.1856), // Worabe location
                zoom: 15,
              ),
              // Limit zoom
              markers: _markers,
              onTap: (LatLng location) {
                _checkPermissions(Permission.location, context);
                setState(() {
                  _selectedLocation = location;
                  _addMarker(location);
                });
                _updateAddress(location);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedLocation != null) {
            Navigator.pop(context, _selectedLocation);
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
