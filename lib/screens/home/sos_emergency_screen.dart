import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/emergency_contact_model.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  SOSScreenState createState() => SOSScreenState();
}

class SOSScreenState extends State<SOSScreen> {
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = false;
  bool _isSendingAlert = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser =
          Provider.of<AuthService>(context, listen: false).currentUser;
      if (currentUser != null) {
        final contacts =
            await Provider.of<DatabaseService>(context, listen: false)
                .getEmergencyContacts(currentUser.uid);

        if (mounted) {
          setState(() {
            _emergencyContacts = contacts;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load emergency contacts');
      }
    }
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => _buildAddContactDialog(),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    setState(() {
      _isSendingAlert = true;
    });

    try {
      final currentUser =
          Provider.of<AuthService>(context, listen: false).currentUser;
      if (currentUser != null) {
        // Send alert to emergency contacts via SMS or other notification method
        for (var contact in _emergencyContacts) {
          await _sendSMSAlert(contact.phoneNumber, currentUser);
        }

        // Optionally call emergency services
        await _callEmergencyServices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent to your contacts'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send emergency alert');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
      }
    }
  }

  Future<void> _sendSMSAlert(String phoneNumber, User user) async {
    final message =
        'EMERGENCY ALERT: ${user.displayName ?? 'User'} needs immediate help! '
        'Current location: https://maps.google.com/'; // Placeholder location

    final Uri smsUri = Uri.parse('sms:$phoneNumber?body=$message');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch $smsUri';
    }
  }

  Future<void> _callEmergencyServices() async {
    final Uri phoneUri =
        Uri.parse('tel:911'); // Adjust based on local emergency number
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildAddContactDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Contact Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty &&
                phoneController.text.isNotEmpty) {
              try {
                final currentUser =
                    Provider.of<AuthService>(context, listen: false)
                        .currentUser;
                if (currentUser != null) {
                  await Provider.of<DatabaseService>(context, listen: false)
                      .addEmergencyContact(
                    currentUser.uid,
                    EmergencyContact(
                      name: nameController.text,
                      phoneNumber: phoneController.text,
                    ),
                  );

                  // Reload contacts
                  await _loadEmergencyContacts();

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Failed to add contact');
                }
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Emergency SOS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Press the button below to send an emergency alert to your contacts and call emergency services.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSendingAlert ? null : _sendEmergencyAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: _isSendingAlert
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SEND EMERGENCY ALERT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addEmergencyContact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _emergencyContacts.isEmpty
                        ? const Center(
                            child: Text(
                              'No emergency contacts added',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _emergencyContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _emergencyContacts[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(contact.name),
                                subtitle: Text(contact.phoneNumber),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      final currentUser =
                                          Provider.of<AuthService>(context,
                                                  listen: false)
                                              .currentUser;
                                      if (currentUser != null) {
                                        await Provider.of<DatabaseService>(
                                                context,
                                                listen: false)
                                            .deleteEmergencyContact(
                                                currentUser.uid,
                                                contact.id ?? '');
                                        await _loadEmergencyContacts();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showErrorSnackBar(
                                            'Failed to delete contact');
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
