import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFAQSection(),
          const SizedBox(height: 24),
          _buildContactSection(context),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          question: 'How do I reset my password?',
          answer: 'Go to the Security section and select "Change Password".',
        ),
        _buildFAQItem(
          question: 'How do I update my profile?',
          answer: 'Navigate to Edit Profile from the main profile screen.',
        ),
        _buildFAQItem(
          question: 'How do I contact support?',
          answer: 'You can reach us through email or phone listed below.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.email, color: Colors.blue),
          title: const Text('Email Support'),
          subtitle: const Text('support@example.com'),
          onTap: () {
            // TODO: Implement email launch
          },
        ),
        ListTile(
          leading: const Icon(Icons.phone, color: Colors.green),
          title: const Text('Phone Support'),
          subtitle: const Text('+1 (555) 123-4567'),
          onTap: () {
            // TODO: Implement phone call
          },
        ),
      ],
    );
  }
} 