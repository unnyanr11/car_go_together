import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import 'payment_method_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = false;
  UserModel? _user;
  String? _errorMessage;

  // Mock transaction history
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'type': 'credit',
      'amount': 500,
      'description': 'Added to wallet',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '2',
      'type': 'debit',
      'amount': 200,
      'description': 'Trip payment',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': '3',
      'type': 'credit',
      'amount': 1000,
      'description': 'Added to wallet',
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': '4',
      'type': 'debit',
      'amount': 300,
      'description': 'Trip payment',
      'date': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'id': '5',
      'type': 'credit',
      'amount': 500,
      'description': 'Referral bonus',
      'date': DateTime.now().subtract(const Duration(days: 10)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserWallet();
  }

  Future<void> _loadUserWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final user = await Provider.of<DatabaseService>(context, listen: false)
          .getUser(userId);

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load wallet. Please try again.';
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
          name: displayName, // Fixed: using name instead of fullName
          email: email,
          phone: '+92300000000', // Fixed: using phone instead of phoneNumber
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          walletBalance: 1500,
          profileImageUrl: null,
          savedPlaces: [],
          rating: 4.5,
          ratingCount: 10,
        );
      });
    }
  }

  void _showAddMoneyDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (PKR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a payment method:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              onTap: () {
                Navigator.pop(context);

                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Process payment
                // In a real app, this would open a payment gateway
                // For demo, we'll just update the balance
                _addMoney(amount);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Bank Transfer'),
              onTap: () {
                Navigator.pop(context);

                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Process payment
                // In a real app, this would open a bank transfer screen
                // For demo, we'll just update the balance
                _addMoney(amount);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mobile_friendly),
              title: const Text('Mobile Wallet'),
              onTap: () {
                Navigator.pop(context);

                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Process payment
                // In a real app, this would open a mobile wallet screen
                // For demo, we'll just update the balance
                _addMoney(amount);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMoney(double amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_user != null) {
        final newBalance = _user!.walletBalance + amount;
        // Use updateUser instead of updateWalletBalance since that method doesn't exist
        await Provider.of<DatabaseService>(context, listen: false)
            .updateUser(_user!.copyWith(walletBalance: newBalance));

        // Add to transactions
        _transactions.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'credit',
          'amount': amount,
          'description': 'Added to wallet',
          'date': DateTime.now(),
        });

        setState(() {
          _user = _user!.copyWith(walletBalance: newBalance);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $amount PKR to your wallet'),
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
            content: Text('Failed to add money. Please try again.'),
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
        title: const Text('Wallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserWallet,
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
                        onPressed: _loadUserWallet,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserWallet,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wallet balance card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  Color(0xFF66BB6A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(
                                      76), // Fixed deprecated withOpacity
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Wallet Balance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_user?.walletBalance.toInt() ?? 0} PKR',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Add Money',
                                        onPressed: _showAddMoneyDialog,
                                        backgroundColor: Colors.white,
                                        textColor: AppColors.primary,
                                        height: 40,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Payment Methods',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PaymentMethodScreen(),
                                            ),
                                          );
                                        },
                                        backgroundColor: Colors.grey.withAlpha(
                                            51), // Fixed deprecated withOpacity
                                        textColor: Colors.white,
                                        height: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Transaction history
                          const Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _transactions.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 32.0),
                                    child: Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _transactions.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final transaction = _transactions[index];
                                    final isCredit =
                                        transaction['type'] == 'credit';

                                    return ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isCredit
                                              ? Colors.green.withAlpha(
                                                  26) // Fixed deprecated withOpacity
                                              : Colors.red.withAlpha(
                                                  26), // Fixed deprecated withOpacity
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCredit
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: isCredit
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                      title: Text(
                                        transaction['description'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _formatDate(transaction[
                                            'date']), // Fixed function call
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${isCredit ? '+' : '-'}${transaction['amount']} PKR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCredit
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // Fixed method name with underscore to indicate it's private
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
