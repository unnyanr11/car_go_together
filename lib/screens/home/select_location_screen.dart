import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../../models/location_model.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectLocationScreen extends StatefulWidget {
  final String title;

  const SelectLocationScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Default location set to the specified coordinates
  static const LatLng _defaultLocation = LatLng(23.0775, 76.8513);

  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  LatLng _selectedPosition = _defaultLocation;
  String _address = '';
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        // Try to get current location
        await _getCurrentLocation();
      } else {
        // If location services are disabled, use default location
        _updateLocationState(_defaultLocation);
      }
    } catch (e) {
      // Fallback to default location if there's an error
      _updateLocationState(_defaultLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await _handleLocationPermission();

      if (permission == LocationPermission.denied) {
        // Use default location if permissions are denied
        _updateLocationState(_defaultLocation);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update location state with current position
      _updateLocationState(
        LatLng(position.latitude, position.longitude),
        shouldAnimateCamera: true,
      );
    } catch (e) {
      // Use default location if there's an error
      _updateLocationState(_defaultLocation);
      _showErrorSnackBar('Error getting current location');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateLocationState(LatLng position,
      {bool shouldAnimateCamera = false}) {
    setState(() {
      _selectedPosition = position;
      _updateMarker();
      _getAddressFromLatLng();
    });

    if (shouldAnimateCamera) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }

  Future<LocationPermission> _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition,
          infoWindow: InfoWindow(
            title: _address.isNotEmpty ? _address : 'Selected Location',
          ),
        ),
      };
    });
  }

  Future<void> _getAddressFromLatLng() async {
    // In a real app, use a geocoding service
    // For now, we'll use a mock address
    setState(() {
      _address = 'Location near Bhopal, Madhya Pradesh, India';
    });
    _updateMarker();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulated search results
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _searchResults = [
          LocationModel.fromGeoPoint(
            id: '1',
            userId: '',
            name: 'Fast NU, Main Campus',
            address: 'Gulshan-e-hadeed, Karachi, Pakistan',
            geoPoint: const GeoPoint(24.8607, 67.0011),
          ),
          LocationModel.fromGeoPoint(
            id: '2',
            userId: '',
            name: 'Shahrah-e-faisal',
            address: 'Shahrah-e-faisal, Karachi, Pakistan',
            geoPoint: const GeoPoint(24.8679, 67.0814),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    _updateLocationState(position);
  }

  void _confirmLocation() {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final location = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: _address.split(',').first,
      address: _address,
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      type: 'other',
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, location);
  }

  void _selectSearchResult(LocationModel location) {
    final selectedPosition = LatLng(
      location.latitude,
      location.longitude,
    );

    setState(() {
      _selectedPosition = selectedPosition;
      _address = location.address;
      _updateMarker();
      _searchResults = [];
      _searchController.text = location.address;
    });

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(selectedPosition, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Use Current Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search TextField (existing code)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(76),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a place',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: _searchPlaces,
                    ),
                  ),

                  // Search Results (existing code)
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(76),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on),
                                    title: Text(result.name),
                                    subtitle: Text(
                                      result.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectSearchResult(result),
                                  );
                                },
                              ),
                      ),
                    ),

                  // Location Confirmation (existing code)
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(76),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup place',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _address.isNotEmpty
                              ? _address
                              : 'Tap on the map to select a location',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _confirmLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedPosition, 15),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
