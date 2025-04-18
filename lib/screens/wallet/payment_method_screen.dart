import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  // Mock payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': '1',
      'type': 'card',
      'brand': 'Visa',
      'last4': '4242',
      'expMonth': 12,
      'expYear': 2024,
      'isDefault': true,
    },
    {
      'id': '2',
      'type': 'card',
      'brand': 'Mastercard',
      'last4': '5555',
      'expMonth': 10,
      'expYear': 2025,
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _paymentMethods.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'No payment methods added yet',
                        style: TextStyle(
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = _paymentMethods[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: method['isDefault']
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: method['isDefault'] ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(
                                      26), // Fixed deprecated withOpacity
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  method['brand'] == 'Visa'
                                      ? Icons.credit_card
                                      : Icons.credit_card,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          method['brand'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (method['isDefault']) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withAlpha(
                                                  26), // Fixed deprecated withOpacity
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '**** **** **** ${method['last4']}',
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    Text(
                                      'Expires ${method['expMonth']}/${method['expYear']}',
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.textLight,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'set_default',
                                    enabled: !method['isDefault'],
                                    onTap: () {
                                      setState(() {
                                        for (var m in _paymentMethods) {
                                          m['isDefault'] =
                                              m['id'] == method['id'];
                                        }
                                      });
                                    },
                                    child: const Text('Set as Default'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    onTap: null,
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),
            const Text(
              'Other Payment Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildPaymentOption(
                      icon: Icons.account_balance,
                      title: 'Bank Transfer',
                      subtitle: 'Transfer from your bank account',
                      onTap: () {
                        // Show bank transfer options
                      },
                    ),
                    const Divider(),
                    _buildPaymentOption(
                      icon: Icons.mobile_friendly,
                      title: 'Mobile Wallet',
                      subtitle: 'Pay using your mobile wallet',
                      onTap: () {
                        // Show mobile wallet options
                      },
                    ),
                    const Divider(),
                    _buildPaymentOption(
                      icon: Icons.money,
                      title: 'Cash',
                      subtitle: 'Pay with cash',
                      onTap: () {
                        // Show cash payment options
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            CustomButton(
              text: 'Add New Payment Method',
              onPressed: () {
                _showAddPaymentMethodDialog();
              },
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  // Fixed the incomplete method
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color:
                    Colors.grey.withAlpha(26), // Fixed deprecated withOpacity
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
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

  // Implemented the missing method
  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              onTap: () {
                Navigator.pop(context);
                _showAddCardDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Bank Account'),
              onTap: () {
                Navigator.pop(context);
                // Show add bank account dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bank account functionality coming soon'),
                  ),
                );
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

  // Renamed to match the call in _showAddPaymentMethodDialog
  void _showAddCardDialog() {
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        hintText: '12/25',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Validate input
              if (cardNumberController.text.isEmpty ||
                  expiryController.text.isEmpty ||
                  cvvController.text.isEmpty ||
                  nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              // In a real app, this would call a payment API
              // For demo, we'll just add a mock card

              // Extract month and year from expiry
              final expiryParts = expiryController.text.split('/');
              if (expiryParts.length != 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid expiry format. Please use MM/YY'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final month = int.tryParse(expiryParts[0]);
              final year = int.tryParse(expiryParts[1]);

              if (month == null || year == null || month < 1 || month > 12) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid expiry date'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final cardNumber = cardNumberController.text.replaceAll(' ', '');
              final last4 = cardNumber.length > 4
                  ? cardNumber.substring(cardNumber.length - 4)
                  : cardNumber;

              // Determine card brand based on first digit
              String brand = 'Unknown';
              if (cardNumber.startsWith('4')) {
                brand = 'Visa';
              } else if (cardNumber.startsWith('5')) {
                brand = 'Mastercard';
              } else if (cardNumber.startsWith('3')) {
                brand = 'American Express';
              } else if (cardNumber.startsWith('6')) {
                brand = 'Discover';
              }

              setState(() {
                _paymentMethods.add({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'type': 'card',
                  'brand': brand,
                  'last4': last4,
                  'expMonth': month,
                  'expYear': 2000 + year,
                  'isDefault': _paymentMethods.isEmpty,
                });
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card added successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
