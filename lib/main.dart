import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'constants/app_colors.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    // Check initial authentication state
    final user = FirebaseAuth.instance.currentUser;

    // Run the app
    runApp(MyApp(
      isFirstLaunch: isFirstLaunch,
      initialUser: user,
    ));
  } catch (e) {
    // Handle Firebase initialization errors
    runApp(ErrorApp(error: e));
  }
}

// Error App for Firebase initialization failures
class ErrorApp extends StatelessWidget {
  final dynamic error;

  const ErrorApp({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  final User? initialUser;

  const MyApp({
    Key? key,
    required this.isFirstLaunch,
    required this.initialUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),

        // Database Service Provider
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),

        // Notification Service Provider
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),

        // Stream Provider for Authentication State
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: initialUser,
        ),
      ],
      child: MaterialApp.router(
        title: 'Car Go Together',
        theme: _buildAppTheme(),

        // Use GoRouter configuration
        routerConfig: AppRouter.router,

        // Maintain debug settings
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  // Extract theme configuration to a separate method
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),

      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
      ).copyWith(
        secondary: AppColors.accent,
        error: AppColors.error,
      ),
    );
  }
}

// Router Configuration (replace previous routing in routes.dart)
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
  GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/onboarding',
    debugLogDiagnostics: true,

    // Redirect logic
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;

      // Public routes
      final publicRoutes = [
        '/onboarding',
        '/login',
        '/signup',
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // Redirect logic based on first launch and authentication
      if (isFirstLaunch()) {
        return '/onboarding';
      }

      if (user == null && !isPublicRoute) {
        return '/login';
      }

      // Email verification check
      if (user != null && !user.emailVerified) {
        return '/email-verification';
      }

      return null;
    },

    // Routes Configuration
    routes: [
      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Direct Signup Route
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Email Verification
      GoRoute(
        path: '/email-verification',
        builder: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          return EmailVerificationScreen(
            email: user?.email ?? '',
            onVerificationComplete: () {
              // Handle verification complete
            },
          );
        },
      ),

      // Home Route
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
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

  // Helper method to check first launch
  static bool isFirstLaunch() {
    // Implement your first launch logic here
    // This is a placeholder and should be replaced with actual implementation
    return false;
  }
}

// Navigation Extension for easier navigation
extension NavigationExtension on BuildContext {
  // Navigation methods
  void goToOnboarding() => go('/onboarding');
  void goToLogin() => go('/login');
  void goToSignup() => go('/signup'); // Updated to direct signup route
  void goToEmailVerification() => go('/email-verification');
  void goToHome() => go('/home');

  // Generic back navigation
  void goBack() => pop();
}