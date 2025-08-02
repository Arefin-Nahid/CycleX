import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ssl_commerz_service.dart';
import '../services/api_service.dart';
import 'SSLCommerzWebView.dart';
import '../Config/routes/PageConstants.dart';

class SSLPaymentScreen extends StatefulWidget {
  final String rentalId;
  final double amount;
  final Map<String, dynamic> rentalData;

  const SSLPaymentScreen({
    Key? key,
    required this.rentalId,
    required this.amount,
    required this.rentalData,
  }) : super(key: key);

  @override
  State<SSLPaymentScreen> createState() => _SSLPaymentScreenState();
}

class _SSLPaymentScreenState extends State<SSLPaymentScreen> {
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  // Customer info form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Starting SSL payment process for rental: ${widget.rentalId}');
      print('💰 Amount: ${widget.amount}');

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      print('✅ User authenticated: ${user.uid}');

      // Prepare customer info
      final customerInfo = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'postcode': '1000', // Default for Bangladesh
      };

      // Create SSL payment session
      print('🔍 About to create SSL session with data:');
      print('  Rental ID: ${widget.rentalId}');
      print('  Amount: ${widget.amount}');
      print('  Customer Info: $customerInfo');

      final sessionResponse = await SSLCommerzService.createPaymentSession(
        rentalId: widget.rentalId,
        amount: widget.amount,
        customerInfo: customerInfo,
      );

      print('✅ SSL session created: $sessionResponse');

      final session = sessionResponse['session'];
      final gatewayUrl = session['gatewayUrl'];
      final transactionId = session['transactionId'];

      // Launch payment gateway using WebView
      await launchSSLCommerzPayment(
        context: context,
        gatewayUrl: gatewayUrl,
        transactionId: transactionId,
        amount: widget.amount,
        onPaymentComplete: (bool success) {
          if (mounted) {
            if (success) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment successful! Redirecting to dashboard.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              // Navigate to RenterDashboard with proper stack management
              try {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  PageConstants.renterDashboardScreen,
                      (route) => false,
                );
              } catch (e) {
                print('Navigation error: $e');
                // Fallback navigation - go to splash screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  PageConstants.splashScreen,
                      (route) => false,
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment was cancelled or failed.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        },
      );

    } catch (e) {
      print('❌ Error processing payment: $e');
      setState(() {
        _errorMessage = 'Failed to process payment: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Color _getColor(BuildContext context, Color light, Color dark) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getColor(context, Colors.white, Colors.grey[900]!),
      appBar: AppBar(
        backgroundColor: _getColor(context, Colors.teal.shade700, Colors.teal.shade900),
        elevation: 0,
        title: Text(
          'Payment Gateway',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_getColor(context, Colors.teal, Colors.tealAccent)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getColor(context, Colors.grey.shade50, Colors.grey[850]!),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getColor(context, Colors.grey.shade200, Colors.grey[800]!)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary',
                      style: TextStyle(
                        color: _getColor(context, Colors.black, Colors.white),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Rental details
                    Row(
                      children: [
                        Icon(Icons.directions_bike, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.rentalData['cycle']?['brand'] ?? 'Unknown'} ${widget.rentalData['cycle']?['model'] ?? 'Cycle'}',
                                style: TextStyle(
                                  color: _getColor(context, Colors.black, Colors.white),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Duration: ${widget.rentalData['duration']?.toStringAsFixed(1) ?? '0'} hours',
                                style: TextStyle(
                                  color: _getColor(context, Colors.grey.shade600, Colors.grey.shade400),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            color: _getColor(context, Colors.black, Colors.white),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '৳${widget.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.greenAccent.shade400,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Customer Information
              Text(
                'Customer Information',
                style: TextStyle(
                  color: _getColor(context, Colors.black, Colors.white),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(
                      color: _getColor(context, Colors.black87, Colors.white)
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.person, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                  filled: true,
                  fillColor: _getColor(context, Colors.white, Colors.grey[850]!),
                ),
                style: TextStyle(color: _getColor(context, Colors.black, Colors.white)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: _getColor(context, Colors.black87, Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.email, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                  filled: true,
                  fillColor: _getColor(context, Colors.white, Colors.grey[850]!),
                ),
                style: TextStyle(color: _getColor(context, Colors.black, Colors.white)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: _getColor(context, Colors.black87, Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.phone, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                  filled: true,
                  fillColor: _getColor(context, Colors.white, Colors.grey[850]!),
                ),
                style: TextStyle(color: _getColor(context, Colors.black, Colors.white)),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(value.trim())) {
                    return 'Please enter a valid Bangladesh phone number';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: _getColor(context, Colors.black87, Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                  filled: true,
                  fillColor: _getColor(context, Colors.white, Colors.grey[850]!),
                ),
                style: TextStyle(color: _getColor(context, Colors.black, Colors.white)),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // City field
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  labelStyle: TextStyle(color: _getColor(context, Colors.black87, Colors.white)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_city, color: _getColor(context, Colors.teal, Colors.tealAccent)),
                  filled: true,
                  fillColor: _getColor(context, Colors.white, Colors.grey[850]!),
                ),
                style: TextStyle(color: _getColor(context, Colors.black, Colors.white)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) SizedBox(height: 16),

              // Payment button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColor(context, Colors.teal.shade700, Colors.teal.shade900),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'Pay Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Security notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColor(context, Colors.blue.withOpacity(0.1), Colors.blueGrey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getColor(context, Colors.blue.withOpacity(0.3), Colors.blueGrey.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: _getColor(context, Colors.blue, Colors.blueAccent), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment information is secure and encrypted.',
                        style: TextStyle(
                          color: _getColor(context, Colors.blue.shade700, Colors.blue.shade200),
                          fontSize: 12,
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
    );
  }
}