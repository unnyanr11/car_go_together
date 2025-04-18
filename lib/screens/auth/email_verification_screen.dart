import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; // Add this import

import '../../constants/app_colors.dart';
import '../../routes.dart'; // Ensure you have your routes defined here

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerificationComplete;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerificationComplete,
  });

  @override
  EmailVerificationScreenState createState() => EmailVerificationScreenState();
}

class EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Verification timer for rapid checks
  Timer? _verificationTimer;

  // State variables
  bool _isVerifying = false;
  bool _canResendEmail = false;
  int _remainingSeconds = 60;

  // Countdown timer for resend email
  Timer? _resendCountdownTimer;

  // Verification attempts tracker
  int _verificationAttempts = 0;
  static const int _maxVerificationAttempts = 100; // Prevent infinite checking

  @override
  void initState() {
    super.initState();

    // Start automatic verification checks
    _startRapidVerificationCheck();

    // Initialize resend email countdown
    _startResendCountdown();
  }

  void _startRapidVerificationCheck() {
    _verificationTimer = Timer.periodic(
        const Duration(milliseconds: 2500), // Slightly reduced frequency
        (_) {
      // Prevent excessive checking
      if (_verificationAttempts >= _maxVerificationAttempts) {
        _verificationTimer?.cancel();
        _showMaxAttemptsDialog();
        return;
      }

      _checkEmailVerification();
    });
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Failed'),
        content: const Text(
            'Maximum verification attempts reached. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () {
              // Use GoRouter for navigation
              context.go(AppRoutes.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startResendCountdown() {
    _canResendEmail = false;
    _remainingSeconds = 60;

    _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    // Prevent multiple simultaneous checks
    if (_isVerifying) return;

    try {
      setState(() {
        _isVerifying = true;
        _verificationAttempts++;
      });

      // Get current user and reload
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      // Check verification status
      if (user != null && user.emailVerified) {
        // Stop verification timer
        _verificationTimer?.cancel();

        // Navigate to home screen
        await _navigateToHomeScreen();
      }
    } catch (e) {
      // Use conditional logging for debug builds
      assert(() {
        debugPrint('Verification check error: $e');
        return true;
      }());
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _navigateToHomeScreen() async {
    // Call verification complete callback if provided
    widget.onVerificationComplete?.call();

    if (mounted) {
      // Use GoRouter for navigation
      context.go(AppRoutes.home);
    }
  }

  Future<void> _resendVerificationEmail() async {
    // Check if email can be resent
    if (!_canResendEmail) return;

    try {
      setState(() {
        _isVerifying = true;
        _canResendEmail = false;
        _verificationAttempts = 0; // Reset attempts
      });

      // Send verification email
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      // Show success snackbar
      _showSnackBar(
        'Verification email resent',
        isError: false,
      );

      // Restart resend countdown
      _startResendCountdown();
    } catch (e) {
      // Show error snackbar
      _showSnackBar(
        'Failed to resend verification email: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Use GoRouter for navigation
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    // Cancel all timers to prevent memory leaks
    _verificationTimer?.cancel();
    _resendCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Email'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A verification email has been sent to ${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your inbox and spam folder.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),

                // Verification Progress Indicator
                LinearProgressIndicator(
                  value: _verificationAttempts / _maxVerificationAttempts,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),

                // Verification Check Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _isVerifying ? null : _checkEmailVerification,
                  child: _isVerifying
                      ? const CircularProgressIndicator.adaptive()
                      : const Text('Check Verification'),
                ),
                const SizedBox(height: 16),

                // Resend Email Button
                TextButton(
                  onPressed: _canResendEmail && !_isVerifying
                      ? _resendVerificationEmail
                      : null,
                  child: _canResendEmail
                      ? const Text('Resend Verification Email')
                      : Text('Resend in $_remainingSeconds seconds'),
                ),

                // Verification Attempts Display
                const SizedBox(height: 16),
                Text(
                  'Verification Attempts: $_verificationAttempts/$_maxVerificationAttempts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
