import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import '../../constants/app_colors.dart';
import '../../models/location_model.dart';
import '../../services/auth_service.dart';

class SelectLocationScreen extends StatefulWidget {
  static const String googleApiKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'fallback_dev_key');

  final String title;
  final bool isDestination;

  const SelectLocationScreen({
    Key? key,
    required this.title,
    this.isDestination = false,
  }) : super(key: key);

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final _logger = Logger('SelectLocationScreen');

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _uuid = const Uuid();

  // Default location set to a central point
  static const LatLng _defaultLocation =
      LatLng(23.0775, 76.8513); // Bhopal coordinates

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  LatLng _selectedPosition = _defaultLocation;
  String _address = '';
  final Set<Marker> _markers = {};
  String? _sessionToken;
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition,
          infoWindow: InfoWindow(
            title: _address.isNotEmpty ? _address : 'Selected Location',
          ),
        ),
      );
    });
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled && !widget.isDestination) {
        await _getCurrentLocation();
      } else {
        _updateLocationState(_defaultLocation);
      }
    } catch (e) {
      _logger.warning('Location initialization error: $e');
      _updateLocationState(_defaultLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isSearching = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _updateLocationState(
        LatLng(position.latitude, position.longitude),
        shouldAnimateCamera: true,
      );
    } catch (e) {
      _logger.warning('Get current location error: $e');
      _updateLocationState(_defaultLocation);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = _uuid.v4();
      });
    }

    if (_searchController.text.isNotEmpty) {
      _searchPlaces(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=${SelectLocationScreen.googleApiKey}&sessiontoken=$_sessionToken');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final predictions = jsonDecode(response.body)['predictions'];

        setState(() {
          _searchResults = predictions;
          _isSearching = false;
        });
      }
    } catch (e) {
      _logger.warning('Place search error: $e');
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  String _locationName = '';
  String _locationCategory = '';

  Future<void> _getPlaceDetails(String placeId) async {
    setState(() {
      _isSearching = true;
      _selectedPlaceId = placeId;
    });

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${SelectLocationScreen.googleApiKey}&sessiontoken=$_sessionToken');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['result'];
        final location = result['geometry']['location'];

        final LatLng selectedPosition = LatLng(
          location['lat'],
          location['lng'],
        );

        // Update map and get address
        _updateLocationState(selectedPosition);

        // Set address from place details
        setState(() {
          _address = result['formatted_address'] ?? 'Selected Location';
        });

        // Reset session token
        _sessionToken = null;
      }
    } catch (e) {
      _logger.warning('Place details error: $e');
    } finally {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchFocusNode.unfocus();
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

    if (shouldAnimateCamera && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _address = _constructAddress(placemark);
        });
      } else {
        setState(() {
          _address = 'Location not found';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unable to retrieve location';
      });
    }
  }

  String _constructAddress(geo.Placemark placemark) {
    return [
      placemark.name,
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country
    ].where((element) => element != null && element.isNotEmpty).join(', ');
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
      type: widget.isDestination ? 'destination' : 'pickup',
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: !widget.isDestination
            ? [
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Use Current Location',
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            markers: _markers,
            onTap: (LatLng position) {
              _updateLocationState(position);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Search Results
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result['description']),
                          onTap: () {
                            _getPlaceDetails(result['place_id']);
                            _searchController.text = result['description'];
                          },
                        );
                      },
                    ),
                  ),

                // Location Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(76),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isDestination
                            ? 'Selected Destination'
                            : 'Selected Location',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _address.isNotEmpty
                            ? _address
                            : 'Tap on map or search a location',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Confirm Location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.my_location,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
