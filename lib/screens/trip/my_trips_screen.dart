import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/trip_model.dart';
// Removed unused import: import '../../models/location_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/trip_card.dart';
import 'trip_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<TripModel> _upcomingTrips = [];
  List<TripModel> _pastTrips = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final trips = await Provider.of<DatabaseService>(context, listen: false)
          .getUserTrips(userId);

      if (!mounted) return;

      final now = DateTime.now();
      final upcoming = <TripModel>[];
      final past = <TripModel>[];

      for (final trip in trips) {
        if (trip.departureTime.isAfter(now) && trip.status != 'cancelled') {
          upcoming.add(trip);
        } else {
          past.add(trip);
        }
      }

      setState(() {
        _upcomingTrips = upcoming;
        _pastTrips = past;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load trips: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelTrip(TripModel trip) async {
    try {
      await Provider.of<DatabaseService>(context, listen: false).cancelTrip(
        trip.id,
        trip.rideId,
        trip.seats,
      );

      if (!mounted) return;

      setState(() {
        final index = _upcomingTrips.indexWhere((t) => t.id == trip.id);
        if (index != -1) {
          _upcomingTrips[index] =
              _upcomingTrips[index].copyWith(status: 'cancelled');
          _upcomingTrips.removeAt(index);
          _pastTrips.insert(0, _upcomingTrips[index]);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel trip: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCancelConfirmationDialog(TripModel trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: const Text(
          'Are you sure you want to cancel this trip? You may be charged a cancellation fee depending on how close it is to the departure time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTrip(trip);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(_upcomingTrips, true),
                _buildTripsList(_pastTrips, false),
              ],
            ),
    );
  }

  Widget _buildTripsList(List<TripModel> trips, bool isUpcoming) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.directions_car : Icons.history,
              color: AppColors.textLight,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming trips' : 'No past trips',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Book a ride to see it here'
                  : 'Your trip history will be displayed here',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripCard(
            trip: trip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailsScreen(trip: trip),
                ),
              );
            },
            onCancel: isUpcoming && trip.status != 'cancelled'
                ? () => _showCancelConfirmationDialog(trip)
                : null,
            isUpcoming: isUpcoming,
          );
        },
      ),
    );
  }
}
