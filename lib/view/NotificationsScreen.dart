import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool orderUpdates = true;
  bool promotionalOffers = false;
  bool rideReminders = true;
  bool paymentNotifications = true;
  bool systemUpdates = true;
  bool locationServices = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pushNotifications = prefs.getBool('pushNotifications') ?? true;
      emailNotifications = prefs.getBool('emailNotifications') ?? true;
      orderUpdates = prefs.getBool('orderUpdates') ?? true;
      promotionalOffers = prefs.getBool('promotionalOffers') ?? false;
      rideReminders = prefs.getBool('rideReminders') ?? true;
      paymentNotifications = prefs.getBool('paymentNotifications') ?? true;
      systemUpdates = prefs.getBool('systemUpdates') ?? true;
      locationServices = prefs.getBool('locationServices') ?? true;
    });
  }

  Future<void> _saveNotificationSettings(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade900 
          : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade800 
            : Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark 
                ? [Colors.grey.shade800, Colors.grey.shade900]
                : [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildNotificationSection(
              title: 'General Notifications',
              children: [
                _buildNotificationTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      pushNotifications = value;
                    });
                    _saveNotificationSettings('pushNotifications', value);
                  },
                ),
                _buildNotificationTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive email notifications',
                  value: emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      emailNotifications = value;
                    });
                    _saveNotificationSettings('emailNotifications', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationSection(
              title: 'Ride Notifications',
              children: [
                _buildNotificationTile(
                  title: 'Ride Updates',
                  subtitle: 'Get updates about your rides and rentals',
                  value: orderUpdates,
                  onChanged: (value) {
                    setState(() {
                      orderUpdates = value;
                    });
                    _saveNotificationSettings('orderUpdates', value);
                  },
                ),
                _buildNotificationTile(
                  title: 'Ride Reminders',
                  subtitle: 'Get reminders for active rides',
                  value: rideReminders,
                  onChanged: (value) {
                    setState(() {
                      rideReminders = value;
                    });
                    _saveNotificationSettings('rideReminders', value);
                  },
                ),
                _buildNotificationTile(
                  title: 'Payment Notifications',
                  subtitle: 'Get notified about payments and transactions',
                  value: paymentNotifications,
                  onChanged: (value) {
                    setState(() {
                      paymentNotifications = value;
                    });
                    _saveNotificationSettings('paymentNotifications', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationSection(
              title: 'System & Services',
              children: [
                _buildNotificationTile(
                  title: 'System Updates',
                  subtitle: 'Get notified about app updates and maintenance',
                  value: systemUpdates,
                  onChanged: (value) {
                    setState(() {
                      systemUpdates = value;
                    });
                    _saveNotificationSettings('systemUpdates', value);
                  },
                ),
                _buildNotificationTile(
                  title: 'Location Services',
                  subtitle: 'Allow location-based notifications',
                  value: locationServices,
                  onChanged: (value) {
                    setState(() {
                      locationServices = value;
                    });
                    _saveNotificationSettings('locationServices', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildNotificationSection(
              title: 'Marketing',
              children: [
                _buildNotificationTile(
                  title: 'Promotional Offers',
                  subtitle: 'Receive promotional offers and discounts',
                  value: promotionalOffers,
                  onChanged: (value) {
                    setState(() {
                      promotionalOffers = value;
                    });
                    _saveNotificationSettings('promotionalOffers', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildNotificationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade800 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.teal,
              ),
            ),
          ),
          Column(
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade700 
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade300 
                : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildNotificationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.blue.shade900 
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue.shade700 
              : Colors.blue.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade300 
                    : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blue.shade300 
                      : Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can customize which notifications you receive. Some notifications are essential for the app to function properly.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blue.shade300 
                  : Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 