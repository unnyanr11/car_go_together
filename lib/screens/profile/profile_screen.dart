import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import 'aadhar_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  UserModel? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateAadharVerification() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AadharVerificationScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      try {
        final userId = _user?.id;
        if (userId != null) {
          await Provider.of<DatabaseService>(context, listen: false)
              .verifyUserAadhar(userId, result);

          // Reload user profile to reflect changes
          await _loadUserProfile();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Aadhar verification ${result['isVerified'] ? 'successful' : 'failed'}'),
                backgroundColor:
                    result['isVerified'] ? Colors.green : AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update Aadhar verification: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          color: AppColors.primary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: _user?.profileImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.network(
                                          _user!.profileImageUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.primary,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user?.fullName ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Aadhar Verification Status
                              _buildVerificationStatus(),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add Aadhar Verification Section
                            _buildAadharVerificationSection(),

                            const SizedBox(height: 24),
                            _buildProfileSection(
                              title: 'Personal Information',
                              items: [
                                _buildProfileItem(
                                  icon: Icons.email,
                                  title: 'Email',
                                  value: _user?.email ?? '',
                                ),
                                _buildProfileItem(
                                  icon: Icons.phone,
                                  title: 'Phone',
                                  value: _user?.phone ?? '',
                                ),
                                _buildProfileItem(
                                  icon: Icons.star,
                                  title: 'Rating',
                                  value: _user?.rating != null
                                      ? '${_user!.rating} (${_user!.ratingCount} ratings)'
                                      : 'No ratings yet',
                                ),
                                _buildProfileItem(
                                  icon: Icons.calendar_today,
                                  title: 'Member Since',
                                  value: _user?.createdAt != null
                                      ? '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'
                                      : '',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildProfileSection(
                              title: 'Account Settings',
                              items: [
                                _buildActionItem(
                                  icon: Icons.location_on,
                                  title: 'Saved Places',
                                  onTap: () {
                                    // Navigate to saved places screen
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.credit_card,
                                  title: 'Payment Methods',
                                  onTap: () {
                                    // Navigate to payment methods screen
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.help,
                                  title: 'Help Center',
                                  onTap: () {
                                    // Navigate to help center
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.privacy_tip,
                                  title: 'Privacy Policy',
                                  onTap: () {
                                    // Show privacy policy
                                  },
                                ),
                                _buildActionItem(
                                  icon: Icons.info,
                                  title: 'About App',
                                  onTap: () {
                                    // Show about app information
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVerificationStatus() {
    final isAadharVerified = _user?.aadharVerification?['status'] == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAadharVerified ? Colors.green : Colors.amber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAadharVerified ? Icons.verified : Icons.warning,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isAadharVerified ? 'Verified' : 'Unverified',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAadharVerificationSection() {
    final isAadharVerified = _user?.aadharVerification?['status'] == 'verified';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aadhar Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isAadharVerified)
                TextButton(
                  onPressed: _initiateAadharVerification,
                  child: const Text(
                    'Verify Now',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAadharVerified
                ? 'Your Aadhar has been verified'
                : 'Complete your Aadhar verification to unlock full app features',
            style: TextStyle(
              color: isAadharVerified ? Colors.green : Colors.amber[700],
            ),
          ),
          if (isAadharVerified) ...[
            const SizedBox(height: 12),
            Text(
              'Aadhar Number: ${_user?.aadharVerification?['maskedAadharNumber'] ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildProfileSection({
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

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
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
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
                    ? AppColors.error.withAlpha(26)
                    : AppColors.primary.withAlpha(26),
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
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? AppColors.error : Colors.black,
                ),
              ),
            ),
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
