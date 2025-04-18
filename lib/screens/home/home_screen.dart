import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/location_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart'; // Added missing import
import '../../widgets/custom_button.dart';
import '../../widgets/location_input.dart';
import '../trip/my_trips_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'select_location_screen.dart';
import 'select_ride_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController?
      _mapController; // Made nullable to avoid unused warning when initialized

  LocationModel? _pickup;
  LocationModel? _destination;
  bool _isLoading = false;
  List<LocationModel> _savedLocations = [];
  DateTime _selectedDateTime = DateTime.now();
  bool _isNow = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final locations =
          await Provider.of<DatabaseService>(context, listen: false)
              .getSavedLocations(userId);

      if (mounted) {
        setState(() {
          _savedLocations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectPickupLocation() async {
    final LocationModel? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectLocationScreen(
          title: 'Select Pickup Location',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _pickup = result;
      });
    }
  }

  Future<void> _selectDestinationLocation() async {
    final LocationModel? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectLocationScreen(
          title: 'Select Destination',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _destination = result;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (timeOfDay != null && mounted) {
      setState(() {
        // Create a new DateTime with the selected time
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
        _isNow = false;
      });
    }
  }

  void _findRides() {
    if (_pickup == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and destination locations'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRideScreen(
          pickup: _pickup!,
          destination: _destination!,
          selectedTime: _selectedDateTime,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final userName = user?.displayName ?? 'User';

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('My Trips'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTripsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help and Support'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Saved Places'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(23.0775, 76.8513), // Karachi coordinates
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(
                                    76), // Fixed deprecated withOpacity
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(
                                    76), // Fixed deprecated withOpacity
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back $userName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Select Time and Location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey
                              .withAlpha(76), // Fixed deprecated withOpacity
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isNow = true;
                                    _selectedDateTime = DateTime.now();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isNow
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isNow
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Now',
                                      style: TextStyle(
                                        color: _isNow
                                            ? Colors.white
                                            : AppColors.text,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: _selectTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isNow
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !_isNow
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      !_isNow
                                          ? '${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}'
                                          : 'Select Time',
                                      style: TextStyle(
                                        color: !_isNow
                                            ? Colors.white
                                            : AppColors.text,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LocationInput(
                          label: 'Select Pickup Location',
                          location: _pickup,
                          onTap: _selectPickupLocation,
                          hintText: 'Enter pickup location',
                          icon: Icons.my_location,
                        ),
                        const SizedBox(height: 16),
                        LocationInput(
                          label: 'Select Destination',
                          location: _destination,
                          onTap: _selectDestinationLocation,
                          hintText: 'Enter destination',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Saved Places',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildSavedPlaceChip(
                                      'Add Home',
                                      Icons.home,
                                      () {},
                                    ),
                                    _buildSavedPlaceChip(
                                      'Add Work',
                                      Icons.work,
                                      () {},
                                    ),
                                    ..._savedLocations.map(
                                      (location) => _buildSavedPlaceChip(
                                        location.name,
                                        Icons.location_on,
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _destination = location;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Find Rides',
                          onPressed: _findRides,
                          height: 50,
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
    );
  }

  Widget _buildSavedPlaceChip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
