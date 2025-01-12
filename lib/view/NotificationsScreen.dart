import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: pushNotifications,
            onChanged: (bool value) {
              setState(() {
                pushNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive email notifications'),
            value: emailNotifications,
            onChanged: (bool value) {
              setState(() {
                emailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Order Updates'),
            subtitle: const Text('Get updates about your orders'),
            value: orderUpdates,
            onChanged: (bool value) {
              setState(() {
                orderUpdates = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Promotional Offers'),
            subtitle: const Text('Receive promotional offers and discounts'),
            value: promotionalOffers,
            onChanged: (bool value) {
              setState(() {
                promotionalOffers = value;
              });
            },
          ),
        ],
      ),
    );
  }
} 