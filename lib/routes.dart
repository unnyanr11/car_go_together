import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/trip_model.dart';
import 'models/ride_model.dart';
import 'models/location_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/email_verification_screen.dart';// Ensure this import exists
import 'screens/home/home_screen.dart';
import 'screens/home/select_location_screen.dart';
import 'screens/home/select_ride_screen.dart';
import 'screens/trip/my_trips_screen.dart';
import 'screens/trip/trip_details_screen.dart';
import 'screens/trip/ride_confirmation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wallet/payment_method_screen.dart';

// Define route names as constants for easier reference
class AppRoutes {
  // Auth Routes
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';

  // Home Routes
  static const String home = '/home';
  static const String selectLocation = '/select-location';
  static const String selectRide = '/select-ride';

  // Trip Routes
  static const String myTrips = '/my-trips';
  static const String tripDetails = '/trip-details';
  static const String rideConfirmation = '/ride-confirmation';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // Wallet Routes
  static const String wallet = '/wallet';
  static const String paymentMethod = '/payment-method';
  static const String addPaymentMethod = '/add-payment-method';
}

// Router Configuration
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
  GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,

    // Enhanced Redirect logic with more robust authentication handling
    redirect: (BuildContext context, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;

      // Public routes that don't require authentication
      final publicRoutes = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // Redirect logic
      if (user == null) {
        // Unauthenticated user
        return isPublicRoute ? null : AppRoutes.login;
      }

      // Handle email verification
      if (!user.emailVerified) {
        // If not on email verification screen, redirect to verification
        return state.matchedLocation != AppRoutes.emailVerification
            ? AppRoutes.emailVerification
            : null;
      }

      // Prevent authenticated users from accessing login/signup
      if (isPublicRoute && user.emailVerified) {
        return AppRoutes.home;
      }

      return null;
    },

    // Routes Configuration
    routes: [
      // Onboarding Route
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
        ],
      ),

      // Email Verification
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) {
          final email = FirebaseAuth.instance.currentUser?.email ?? '';
          return EmailVerificationScreen(
            email: email,
            onVerificationComplete: () {
              // Explicitly navigate to home after verification
              context.go(AppRoutes.home);
            },
          );
        },
      ),

      // Home Route with Nested Routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Select Location
          GoRoute(
            path: 'select-location',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              return SelectLocationScreen(
                title: args?['title'] ?? 'Select Location',
              );
            },
          ),
          // Select Ride
          GoRoute(
            path: 'select-ride',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return SelectRideScreen(
                pickup: args['pickup'] as LocationModel,
                destination: args['destination'] as LocationModel,
                selectedTime: args['selectedTime'] as DateTime,
              );
            },
          ),
        ],
      ),

      // Trips Routes
      GoRoute(
        path: AppRoutes.myTrips,
        builder: (context, state) => const MyTripsScreen(),
        routes: [
          // Trip Details
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final trip = state.extra as TripModel;
              return TripDetailsScreen(trip: trip);
            },
          ),
          // Ride Confirmation
          GoRoute(
            path: 'confirmation',
            builder: (context, state) {
              final ride = state.extra as RideModel;
              return RideConfirmationScreen(ride: ride);
            },
          ),
        ],
      ),

      // Profile Routes
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Wallet Routes
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
        routes: [
          GoRoute(
            path: 'payment-method',
            builder: (context, state) => const PaymentMethodScreen(),
          ),
        ],
      ),
    ],

    // Error Page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 100),
            const SizedBox(height: 16),
            const Text(
              'Oops! Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Route: ${state.matchedLocation}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
}

// Navigation Extension for easier navigation
extension NavigationExtension on BuildContext {
  // Navigation methods
  void goToOnboarding() => go(AppRoutes.onboarding);
  void goToLogin() => go(AppRoutes.login);
  void goToSignup() => go(AppRoutes.signup);
  void goToForgotPassword() => go(AppRoutes.forgotPassword);
  void goToEmailVerification() => go(AppRoutes.emailVerification);
  void goToHome() => go(AppRoutes.home);

  // With parameters
  void goToSelectLocation({String? title}) =>
      go('${AppRoutes.home}/select-location', extra: {'title': title});

  void goToSelectRide({
    required LocationModel pickup,
    required LocationModel destination,
    required DateTime selectedTime,
  }) => go('${AppRoutes.home}/select-ride', extra: {
    'pickup': pickup,
    'destination': destination,
    'selectedTime': selectedTime,
  });

  void goToTripDetails(TripModel trip) =>
      go('${AppRoutes.myTrips}/details', extra: trip);

  void goToRideConfirmation(RideModel ride) =>
      go('${AppRoutes.myTrips}/confirmation', extra: ride);

  void goToProfile() => go(AppRoutes.profile);
  void goToSettings() => go('${AppRoutes.profile}/settings');
  void goToWallet() => go(AppRoutes.wallet);
  void goToPaymentMethod() => go('${AppRoutes.wallet}/payment-method');

  // Generic navigation
  void goBack() => pop();
}