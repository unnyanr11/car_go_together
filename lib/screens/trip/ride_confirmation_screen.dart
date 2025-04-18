import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/ride_model.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart'; // Added missing import
import '../../utils/date_time_utils.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/custom_button.dart';
import 'my_trips_screen.dart';

class RideConfirmationScreen extends StatefulWidget {
  final RideModel ride;

  const RideConfirmationScreen({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  bool _isLoading = false;
  int _selectedSeats = 1;
  final List<String> _paymentMethods = [
    'Wallet',
    'Credit/Debit Card',
    'Cash',
  ];
  String _selectedPaymentMethod = 'Wallet';

  double get _totalPrice => widget.ride.price * _selectedSeats;

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser =
          Provider.of<AuthService>(context, listen: false).currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has enough balance if paying with wallet
      if (_selectedPaymentMethod == 'Wallet') {
        final databaseService =
            Provider.of<DatabaseService>(context, listen: false);
        final user = await databaseService.getUser(currentUser.uid);

        if (user.walletBalance < _totalPrice) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Balance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You don\'t have enough balance in your wallet. Please add money to your wallet or select a different payment method.',
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Add Money to Wallet',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/wallet');
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Choose Different Payment Method'),
                  ),
                ],
              ),
            ),
          );

          return;
        }
      }

      // Create a new trip
      final trip = TripModel(
        id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        rideId: widget.ride.id,
        driverId: widget.ride.driverId,
        driverName: widget.ride.driverName,
        driverRating: widget.ride.driverRating,
        pickupLocation: widget.ride.pickupLocation,
        destinationLocation: widget.ride.destinationLocation,
        departureTime: widget.ride.departureTime,
        price: _totalPrice,
        seats: _selectedSeats,
        vehicleModel: widget.ride.vehicleModel,
        vehicleColor: widget.ride.vehicleColor,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      await databaseService.bookTrip(trip);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your ride has been booked successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pickup: ${DateTimeUtils.formatDayAndTime(widget.ride.departureTime)}',
                style: const TextStyle(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          actions: [
            CustomButton(
              text: 'View My Trips',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTripsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book ride: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Date',
                      DateTimeUtils.formatDate(widget.ride.departureTime),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Time',
                      DateTimeUtils.formatTime(widget.ride.departureTime),
                      Icons.access_time,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Driver',
                      widget.ride.driverName,
                      Icons.person,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Vehicle',
                      '${widget.ride.vehicleModel} (${widget.ride.vehicleColor})',
                      Icons.directions_car,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Pickup',
                      widget.ride.pickupLocation.address,
                      Icons.location_on,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      'Destination',
                      widget.ride.destinationLocation.address,
                      Icons.location_on,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of Seats',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _selectedSeats > 1
                                  ? () {
                                      setState(() {
                                        _selectedSeats--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: _selectedSeats > 1
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                            Text(
                              _selectedSeats.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _selectedSeats < widget.ride.availableSeats
                                      ? () {
                                          setState(() {
                                            _selectedSeats++;
                                          });
                                        }
                                      : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: _selectedSeats < widget.ride.availableSeats
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final method in _paymentMethods)
                      RadioListTile<String>(
                        title: Text(method),
                        value: method,
                        groupValue: _selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price per seat',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          CurrencyUtils.formatPKR(widget.ride.price),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Number of seats',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _selectedSeats.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyUtils.formatPKR(_totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Confirm Booking',
              icon: Icons.check_circle,
              isLoading: _isLoading,
              onPressed: _confirmBooking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
