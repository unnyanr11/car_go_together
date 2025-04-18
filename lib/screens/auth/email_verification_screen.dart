import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../routes.dart';

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

class EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  // Verification timer for rapid checks
  Timer? _verificationTimer;

  // Animation controller for continuous progress
  late AnimationController _animationController;

  // State variables
  bool _isVerifying = false;
  bool _emailSent = false;
  bool _canResendEmail = true;
  int _remainingSeconds = 60;

  // Countdown timer for resend email
  Timer? _resendCountdownTimer;

  // Verification attempts tracker
  int _verificationAttempts = 0;
  static const int _maxVerificationAttempts = 100;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    // Cancel all timers to prevent memory leaks
    _verificationTimer?.cancel();
    _resendCountdownTimer?.cancel();
    // Dispose animation controller
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      setState(() {
        _isVerifying = true;
        _canResendEmail = false;
        _emailSent = false;
      });

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Send verification email
        await user.sendEmailVerification();

        // Start verification check
        _startVerificationCheck();

        setState(() {
          _emailSent = true;
          _startResendCountdown();
        });

        _showSnackBar(
          'Verification email sent',
          isError: false,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Failed to send verification email: ${e.toString()}',
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

  void _startVerificationCheck() {
    _verificationTimer?.cancel();
    _verificationAttempts = 0;

    _verificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (_verificationAttempts >= _maxVerificationAttempts) {
          _verificationTimer?.cancel();
          _showMaxAttemptsDialog();
          return;
        }

        _checkEmailVerification();
      },
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_isVerifying) return;

    try {
      setState(() {
        _isVerifying = true;
        _verificationAttempts++;
      });

      // Reload current user
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      // Check if email is verified
      if (user != null && user.emailVerified) {
        _verificationTimer?.cancel();
        await _navigateToHomeScreen();
      }
    } catch (e) {
      debugPrint('Verification check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
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

  Future<void> _navigateToHomeScreen() async {
    // Call the verification complete callback if provided
    widget.onVerificationComplete?.call();

    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Failed'),
        content: const Text(
          'Maximum verification attempts reached. Please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.go(AppRoutes.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
                  'Email: ${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Send Verification Email Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _canResendEmail && !_isVerifying
                      ? _sendVerificationEmail
                      : null,
                  child: _isVerifying
                      ? const CircularProgressIndicator.adaptive()
                      : Text(_emailSent
                          ? 'Resend Verification Email'
                          : 'Send Verification Email'),
                ),

                const SizedBox(height: 16),

                // Resend Cooldown
                if (_emailSent && !_canResendEmail)
                  Text(
                    'Resend in $_remainingSeconds seconds',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                // Verification Progress
                if (_emailSent)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      // Animated Continuous Verification Indicator
                      RotationTransition(
                        turns: _animationController,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 10,
                            ),
                          ),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _verificationAttempts /
                                      _maxVerificationAttempts,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  '$_verificationAttempts',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verification in Progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attempts: $_verificationAttempts/$_maxVerificationAttempts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
                Text(
                  'Please check your inbox and spam folder.',
                  textAlign: TextAlign.center,
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
