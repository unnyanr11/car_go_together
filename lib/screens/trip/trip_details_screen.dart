import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/trip_model.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/custom_button.dart';

class TripDetailsScreen extends StatelessWidget {
  final TripModel trip;

  const TripDetailsScreen({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
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
                      'Trip Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                        'Date', DateTimeUtils.formatDate(trip.departureTime)),
                    const Divider(),
                    _buildInfoRow(
                        'Time', DateTimeUtils.formatTime(trip.departureTime)),
                    const Divider(),
                    _buildInfoRow('Driver', trip.driverName),
                    const Divider(),
                    _buildInfoRow('Vehicle',
                        '${trip.vehicleModel} (${trip.vehicleColor})'),
                    const Divider(),
                    _buildInfoRow(
                        'Pickup Location', trip.pickupLocation.address),
                    const Divider(),
                    _buildInfoRow(
                        'Destination', trip.destinationLocation.address),
                    const Divider(),
                    _buildInfoRow(
                      'Total Paid',
                      CurrencyUtils.formatPKR(trip.price),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  text: trip.status == 'confirmed'
                      ? 'Cancel Trip'
                      : 'Rebook Trip',
                  backgroundColor: trip.status == 'confirmed'
                      ? AppColors.error
                      : AppColors.primary,
                  onPressed: () {
                    // Perform cancellation or rebooking logic
                    final action =
                        trip.status == 'confirmed' ? 'cancel' : 'rebook';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'You chose to $action this trip. Implementation pending.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
