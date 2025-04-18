import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';

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

      // For demo, create a mock user
      if (mounted) {
        final userId =
            Provider.of<AuthService>(context, listen: false).currentUser?.uid ??
                '';
        final displayName = Provider.of<AuthService>(context, listen: false)
                .currentUser
                ?.displayName ??
            'John Doe';
        final email = Provider.of<AuthService>(context, listen: false)
                .currentUser
                ?.email ??
            'john.doe@example.com';

        setState(() {
          _user = UserModel(
            id: userId,
            email: email,
            name: displayName,
            phone: '+92300000000',
            walletBalance: 1000,
            rating: 4.5,
            ratingCount: 10,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          );
        });
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to sign out. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
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
                      expandedHeight: 200,
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
                                  value: _user?.phoneNumber ?? '',
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
                                _buildActionItem(
                                  icon: Icons.logout,
                                  title: 'Sign Out',
                                  onTap: _signOut,
                                  isDestructive: true,
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
              color: AppColors.primary
                  .withAlpha(26), // Fixed deprecated withOpacity
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
                    ? AppColors.error
                        .withAlpha(26) // Fixed deprecated withOpacity
                    : AppColors.primary
                        .withAlpha(26), // Fixed deprecated withOpacity
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
