import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _connectivity = Connectivity();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  final _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
  );

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Hide keyboard during signup process
    FocusScope.of(context).unfocus();

    // Check internet connectivity
    if (!await _checkInternetConnectivity()) {
      _showErrorSnackBar('No internet connection. Please check your network.');
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // try {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // Comprehensive signup process
    await _performSignUp(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
    // } on FirebaseAuthException catch (e) {
    //   // Handle Firebase-specific authentication errors
    //   _handleAuthError(e);
    // } catch (e) {
    //   // Handle any other unexpected errors
    //   _handleUnexpectedError(e);
    // } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // }
  }

  Future<void> _performSignUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // try {
    // Validate form inputs again (extra safety)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check internet connectivity
    if (!await _checkInternetConnectivity()) {
      _showErrorSnackBar('No internet connection. Please check your network.');
      return;
    }

    // Create user account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Ensure user is not null
    final user = userCredential.user;
    if (user == null) {
      _showErrorSnackBar('Failed to create user account.');
      return;
    }

    // Create user document in Firestore
    await _createUserDocument(
      uid: user.uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
    );

    // Update user profile display name
    await user.updateDisplayName(fullName);

    // Send email verification
    await user.sendEmailVerification();

    // Show success message
    _showSuccessSnackBar('Signup Successful!');

    // Immediate navigation to Email Verification Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: email,
            onVerificationComplete: () {
              // Optional: Navigate to home screen after verification
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
    // } on FirebaseAuthException catch (e) {
    // // Handle specific Firebase authentication errors
    // String errorMessage;
    // switch (e.code) {
    //   case 'weak-password':
    //     errorMessage = 'The password is too weak.';
    //     break;
    //   case 'email-already-in-use':
    //     errorMessage = 'This email is already registered.';
    //     break;
    //   case 'invalid-email':
    //     errorMessage = 'Invalid email address.';
    //     break;
    //   case 'operation-not-allowed':
    //     errorMessage = 'Email/password accounts are not enabled.';
    //     break;
    //   default:
    //     errorMessage = 'Authentication failed. Please try again.';
    // }

    // // Show error message
    // setState(() {
    //   _errorMessage = errorMessage;
    // });
    // _showErrorSnackBar(errorMessage);
    // } catch (e) {
    //   // Handle any other unexpected errors
    //   setState(() {
    //     _errorMessage = 'An unexpected error occurred. Please try again.';
    //   });
    //   _showErrorSnackBar(_errorMessage!);

    //   // Optional: Log the error
    //   print('Unexpected signup error: $e');
    // } finally {
    // Ensure loading state is turned off
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // }
  }

  Future<void> _createUserDocument({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'profileImageUrl': '',
      'walletBalance': 0.0,
      'rating': 0.0,
      'ratingCount': 0,
      'isFirstTimeUser': true,
      'status': 'active',
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _checkInternetConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _handleAuthError(FirebaseAuthException e) {
    setState(() {
      _errorMessage = _getFirebaseErrorMessage(e);
    });
    _showErrorSnackBar(_errorMessage!);
  }

  void _handleUnexpectedError(dynamic e) {
    setState(() {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    });
    _showErrorSnackBar(_errorMessage!);

    // Optional: Log the error for debugging
    print('Unexpected signup error: $e');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email is already registered. Try logging in.';
      case 'invalid-email':
        return 'Invalid email format. Please check your email.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final cleanedNumber = value.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanedNumber.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (!_passwordRegex.hasMatch(value.trim())) {
      return 'Password must include uppercase, lowercase, number, and symbol';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Center(
                    child: Text(
                      'Car Go Together',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.background,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name TextField
                  CustomTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: _validateFullName,
                    prefix: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 16),

                  // Email TextField
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    prefix: const Icon(Icons.email),
                  ),
                  const SizedBox(height: 16),

                  // Phone Number TextField
                  CustomTextField(
                    label: 'Phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: _validatePhoneNumber,
                    prefix: const Icon(Icons.phone),
                  ),
                  const SizedBox(height: 16),

                  // Password TextField
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    validator: _validatePassword,
                    prefix: const Icon(Icons.lock),
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message Display
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Signup Button
                  CustomButton(
                    text: 'Sign Up',
                    onPressed: _signUp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Login navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: AppColors.textLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
