import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/location_model.dart';
import '../../models/ride_model.dart';
import '../../services/database_service.dart'; // Added missing import
import '../../widgets/ride_card.dart';
import '../trip/ride_confirmation_screen.dart';

class SelectRideScreen extends StatefulWidget {
  final LocationModel pickup;
  final LocationModel destination;
  final DateTime selectedTime;

  const SelectRideScreen({
    Key? key,
    required this.pickup,
    required this.destination,
    required this.selectedTime,
  }) : super(key: key);

  @override
  State<SelectRideScreen> createState() => _SelectRideScreenState();
}

class _SelectRideScreenState extends State<SelectRideScreen> {
  bool _isLoading = false;
  List<RideModel> _availableRides = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRides();
  }

  Future<void> _fetchAvailableRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rides = await Provider.of<DatabaseService>(context, listen: false)
          .getAvailableRides();

      // Filter rides based on location and time
      // This would be done on the server in a real app

      // If no rides are available, we'll show mock data for demonstration
      if (mounted) {
        if (rides.isEmpty) {
          _generateMockRides();
        } else {
          setState(() {
            _availableRides = rides;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load rides. Please try again.';
          _isLoading = false;
        });

        // For demonstration, show mock data even when there's an error
        _generateMockRides();
      }
    }
  }

  void _generateMockRides() {
    final now = DateTime.now();
    final departureTime = DateTime(
      now.year,
      now.month,
      now.day,
      19,
      30,
    );

    final drivers = [
      {
        'id': '1',
        'name': 'Uzair Ali',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
      {
        'id': '2',
        'name': 'Asad',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
      {
        'id': '3',
        'name': 'Alexa',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
      {
        'id': '4',
        'name': 'Mike',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
      {
        'id': '5',
        'name': 'Taha',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
      {
        'id': '6',
        'name': 'Ashir',
        'rating': 4.5,
        'ratingCount': 2,
        'vehicle': 'Swift',
      },
    ];

    final List<RideModel> mockRides = drivers.map((driver) {
      return RideModel(
        id: driver['id'] as String,
        driverId: driver['id'] as String,
        driverName: driver['name'] as String,
        driverRating: driver['rating'] as double,
        driverRatingCount: driver['ratingCount'] as int,
        pickupLocation: widget.pickup,
        destinationLocation: widget.destination,
        departureTime: departureTime,
        price: 100,
        totalSeats: 4,
        availableSeats: 2,
        vehicleModel: driver['vehicle'] as String,
        vehicleColor: 'White',
        status: 'active',
        createdAt: DateTime.now(),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _availableRides = mockRides;
        _isLoading = false;
      });
    }
  }

  void _bookRide(RideModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideConfirmationScreen(
          ride: ride,
        ),
      ),
    );
  }

  void _requestRide() {
    // Show a dialog to request a custom ride
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request a Ride'),
        content: const Text(
          'Your ride request has been sent. We will notify you when a driver accepts your request.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your ride'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Column(
                  children: [
                    Icon(Icons.circle, size: 12, color: AppColors.primary),
                    SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        color: AppColors.primary,
                        thickness: 1,
                        width: 20,
                      ),
                    ),
                    Icon(Icons.location_on, size: 12, color: AppColors.primary),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pickup.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.destination.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchAvailableRides,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _availableRides.isEmpty
                        ? const Center(
                            child: Text('No rides available at this time'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _availableRides.length,
                            itemBuilder: (context, index) {
                              final ride = _availableRides[index];

                              // For the 4th item, show a Request button instead of Book Now
                              final isRequestRide = index == 3;

                              return RideCard(
                                ride: ride,
                                onTap: () => _bookRide(ride),
                                onBook: isRequestRide
                                    ? _requestRide
                                    : () => _bookRide(ride),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
