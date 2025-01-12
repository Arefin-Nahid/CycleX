import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSecurityOption(
            title: 'Change Password',
            subtitle: 'Update your password',
            icon: Icons.lock_outline,
            onTap: () {
              // TODO: Implement change password functionality
            },
          ),
          _buildSecurityOption(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            icon: Icons.security,
            onTap: () {
              // TODO: Implement 2FA functionality
            },
          ),
          _buildSecurityOption(
            title: 'Login Activity',
            subtitle: 'Check your recent login activity',
            icon: Icons.history,
            onTap: () {
              // TODO: Implement login activity view
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
} 