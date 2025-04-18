import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/trip_model.dart';
import 'custom_button.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final bool isUpcoming;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
    this.onCancel,
    this.isUpcoming = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey
                        .withAlpha(26), // Fixed deprecated withOpacity
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            Text(
                              '${trip.driverRating}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey
                            .withAlpha(26), // Fixed deprecated withOpacity
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Coming in 5 mins',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
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
                      Icon(Icons.location_on,
                          size: 12, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.pickupLocation.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          trip.destinationLocation.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem('Time',
                      '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}pm'),
                  _buildInfoItem('Price', '${trip.price.toInt()} PKR'),
                  _buildInfoItem(
                      'Vehicle', '${trip.vehicleColor} ${trip.vehicleModel}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey
                            .withAlpha(26), // Fixed deprecated withOpacity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trip.status.capitalize(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getStatusColor(trip.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (isUpcoming && onCancel != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel Request',
                        onPressed: onCancel!,
                        backgroundColor: Colors.white,
                        textColor: AppColors.error,
                        height: 38,
                        borderRadius: BorderRadius.circular(
                            8), // Fixed: passing BorderRadius object instead of int
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'upcoming':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
