import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  UserModel? _user;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final user = await Provider.of<DatabaseService>(context, listen: false)
          .getUser(userId);

      setState(() {
        _user = user;
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile. Please try again.';
        _isLoading = false;
      });

      // For demo, create a mock user
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser?.uid ??
              '';
      final displayName = Provider.of<AuthService>(context, listen: false)
              .currentUser
              ?.displayName ??
          'John Doe';
      final email =
          Provider.of<AuthService>(context, listen: false).currentUser?.email ??
              'john.doe@example.com';

      setState(() {
        _user = UserModel(
          id: userId,
          name: displayName,
          email: email,
          phone: '+92300000000',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          walletBalance: 1000,
          profileImageUrl: null,
          savedPlaces: [],
          rating: 4.5,
          ratingCount: 10,
        );

        _nameController.text = displayName;
        _emailController.text = email;
        _phoneController.text = '+92300000000';
      });
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_user != null) {
        final updatedUser = _user!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        await Provider.of<DatabaseService>(context, listen: false)
            .updateUser(updatedUser);

        // Update display name in Firebase Auth
        final user =
            Provider.of<AuthService>(context, listen: false).currentUser;
        if (user != null) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        setState(() {
          _user = updatedUser;
          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditing,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditing,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: _user?.profileImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: Image.network(
                                          _user!.profileImageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.primary,
                                      ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          label: 'Full Name',
                          controller: _nameController,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          prefix: const Icon(Icons.person),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          prefix: const Icon(Icons.email),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          prefix: const Icon(Icons.phone),
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          CustomButton(
                            text: 'Save Changes',
                            onPressed: _saveProfile,
                            isLoading: _isLoading,
                          ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSettingsSection(
                          title: 'App Settings',
                          items: [
                            _buildSettingsItem(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              subtitle: 'Manage notification preferences',
                              onTap: () {
                                // Navigate to notifications settings
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.lock,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              onTap: () {
                                // Navigate to change password screen
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.language,
                              title: 'Language',
                              subtitle: 'English',
                              onTap: () {
                                // Show language selection
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.dark_mode,
                              title: 'Dark Mode',
                              subtitle: 'Off',
                              onTap: () {
                                // Toggle dark mode
                              },
                              trailing: Switch(
                                value: false,
                                onChanged: (value) {
                                  // Toggle dark mode
                                },
                                activeColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsSection(
                          title: 'Privacy',
                          items: [
                            _buildSettingsItem(
                              icon: Icons.privacy_tip,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              onTap: () {
                                // Show privacy policy
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.description,
                              title: 'Terms of Service',
                              subtitle: 'Read our terms of service',
                              onTap: () {
                                // Show terms of service
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.delete_forever,
                              title: 'Delete Account',
                              subtitle: 'Permanently delete your account',
                              onTap: () {
                                // Show delete account confirmation
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Account'),
                                    content: const Text(
                                      'Are you sure you want to delete your account? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Delete account logic
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style:
                                              TextStyle(color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsSection(
                          title: 'About',
                          items: [
                            _buildSettingsItem(
                              icon: Icons.info,
                              title: 'About SafarMilao',
                              subtitle: 'Version 1.0.0',
                              onTap: () {
                                // Show about dialog
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.star,
                              title: 'Rate App',
                              subtitle: 'Rate us on App Store',
                              onTap: () {
                                // Open app store rating
                              },
                            ),
                            _buildSettingsItem(
                              icon: Icons.feedback,
                              title: 'Send Feedback',
                              subtitle: 'Help us improve the app',
                              onTap: () {
                                // Open feedback form
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? AppColors.error : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textLight,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }
}
