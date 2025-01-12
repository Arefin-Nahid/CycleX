import 'package:flutter/material.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailsScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String name;

  const UserDetailsScreen({
    Key? key,
    required this.uid,
    required this.email,
    required this.name,
  }) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSkipped = false;

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();

  Future<void> _submitDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Make sure all these fields have values
        Map<String, dynamic> userData = {
          'uid': widget.uid,      // Make sure this is not null
          'email': widget.email,  // Make sure this is not null
          'name': widget.name,    // Make sure this is not null
          'studentId': _studentIdController.text.trim(),
          'department': _departmentController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        };

        // Add validation to ensure required fields are not null
        if (userData['uid'] == null || userData['email'] == null || userData['name'] == null) {
          throw Exception('Missing required fields');
        }

        final response = await ApiService.registerUser(userData);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, PageConstants.homeScreen);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show warning dialog
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: const Text(
              'You must complete your profile to use the app. Do you want to logout instead?'
            ),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Logout'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      PageConstants.loginScreen,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        );
        return shouldLogout ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF17153A),
        body: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D0C3).withOpacity(0.3),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4D6D).withOpacity(0.3),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Complete Your Profile",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Please provide your additional details",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildFormField(
                              label: "Student ID",
                              controller: _studentIdController,
                              icon: Icons.badge_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your student ID";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: "Department",
                              controller: _departmentController,
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your department";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: "Phone Number",
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your phone number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildFormField(
                              label: "Address",
                              controller: _addressController,
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your address";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D0C3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          "Complete Profile",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: TextButton(
                                onPressed: () async {
                                  final shouldLogout = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout? Your profile is not complete.',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('No'),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text('Yes, Logout'),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldLogout == true && mounted) {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      PageConstants.loginScreen,
                                      (route) => false,
                                    );
                                  }
                                },
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: "Enter your $label",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.7),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFF00D0C3),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFFF4D6D),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFFFF4D6D),
              ),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          validator: validator,
        ),
      ],
    );
  }
} 