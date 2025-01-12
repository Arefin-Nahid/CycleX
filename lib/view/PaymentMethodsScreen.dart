import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPaymentCard(
            cardType: 'Visa',
            lastFourDigits: '4242',
            expiryDate: '12/24',
          ),
          const SizedBox(height: 16),
          _buildPaymentCard(
            cardType: 'Mastercard',
            lastFourDigits: '8888',
            expiryDate: '06/25',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement add new card functionality
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Card'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required String cardType,
    required String lastFourDigits,
    required String expiryDate,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          cardType == 'Visa' ? Icons.credit_card : Icons.credit_card_outlined,
          color: Colors.blue,
        ),
        title: Text('$cardType ending in $lastFourDigits'),
        subtitle: Text('Expires $expiryDate'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            // TODO: Implement delete card functionality
          },
        ),
      ),
    );
  }
} 