import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class AadharVerificationScreen extends StatefulWidget {
  const AadharVerificationScreen({Key? key}) : super(key: key);

  @override
  _AadharVerificationScreenState createState() =>
      _AadharVerificationScreenState();
}

class _AadharVerificationScreenState extends State<AadharVerificationScreen> {
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _verificationResult;

  // UIDAI Verification API (Hypothetical Endpoint)
  static const String _UIDAI_VERIFICATION_URL =
      'https://uidai.gov.in/api/verify';

  Future<void> _verifyAadhar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _verificationResult = null;
    });

    try {
      // Actual UIDAI verification would require official API access
      // This is a simulated verification process
      final response = await _performUIDAIVerification(
        aadharNumber: _aadharController.text,
        name: _nameController.text,
        dob: _dobController.text,
      );

      setState(() {
        _verificationResult = response;
        _isLoading = false;
      });

      // If verification successful, navigate back with verification details
      if (response == 'Verified') {
        Navigator.of(context).pop({
          'aadharNumber': _aadharController.text,
          'name': _nameController.text,
          'dob': _dobController.text,
          'isVerified': true,
        });
      }
    } catch (e) {
      setState(() {
        _verificationResult = 'Verification failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String> _performUIDAIVerification({
    required String aadharNumber,
    required String name,
    required String dob,
  }) async {
    try {
      // Note: This is a simulated API call
      // In reality, you would need official UIDAI API access
      final response = await http.post(
        Uri.parse(_UIDAI_VERIFICATION_URL),
        body: {
          'aadharNumber': aadharNumber,
          'name': name,
          'dateOfBirth': dob,
          'apiKey':
              'YOUR_OFFICIAL_UIDAI_API_KEY', // Requires official registration
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Typical UIDAI verification response structure
        if (result['status'] == 'success' && result['verified'] == true) {
          return 'Verified';
        } else {
          return result['message'] ?? 'Verification failed';
        }
      } else {
        return 'Verification service unavailable';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aadhar Verification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'UIDAI Aadhar Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Aadhar Number Input
              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (value) {
                  if (value == null || value.length != 12) {
                    return 'Please enter a valid 12-digit Aadhar number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name (as per Aadhar)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Input
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your date of birth';
                  }
                  // Add more robust date validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Verification Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyAadhar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify Aadhar',
                        style: TextStyle(fontSize: 18),
                      ),
              ),

              // Verification Result
              if (_verificationResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _verificationResult!,
                    style: TextStyle(
                      color: _verificationResult == 'Verified'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Disclaimer
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  'Note: Verification is done directly with UIDAI. '
                  'Your personal information is secure and will not be stored.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
