import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class SSLCommerzService {
  // Create SSLCommerz payment session
  static Future<Map<String, dynamic>> createPaymentSession({
    required String rentalId,
    required double amount,
    required Map<String, dynamic> customerInfo,
  }) async {
    try {
          print('Creating SSL payment session for rental: $rentalId');
    print('Amount: $amount');

      // Update auth header before making the request
      await ApiService.instance.updateAuthHeader();

      final response = await ApiService.instance.post(
        'payments/ssl/create-session',
        {
          'rentalId': rentalId,
          'amount': amount,
          'customerInfo': customerInfo,
        },
      );

              print('SSL session created successfully: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
              print('Error creating SSL session: $e');
      throw Exception('Failed to create payment session: $e');
    }
  }

  // Launch SSLCommerz payment gateway
  static Future<void> launchPaymentGateway({
    required String gatewayUrl,
    required String transactionId,
    required BuildContext context,
  }) async {
    try {
      print('🔗 Launching SSL gateway: $gatewayUrl');
      
      // Check if URL can be launched
      if (await canLaunchUrl(Uri.parse(gatewayUrl))) {
        await launchUrl(
          Uri.parse(gatewayUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch payment gateway');
      }
    } catch (e) {
              print('Error launching payment gateway: $e');
      throw Exception('Failed to launch payment gateway: $e');
    }
  }

  // Show payment gateway in WebView
  static Future<void> showPaymentGatewayInWebView({
    required String gatewayUrl,
    required String transactionId,
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onFailure,
    required Function() onCancel,
  }) async {
    try {
      print('🌐 Opening SSL gateway in WebView: $gatewayUrl');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SSLCommerzWebView(
            gatewayUrl: gatewayUrl,
            transactionId: transactionId,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onCancel: onCancel,
          ),
        ),
      );
    } catch (e) {
              print('Error showing payment gateway: $e');
      throw Exception('Failed to show payment gateway: $e');
    }
  }

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String transactionId,
  }) async {
    try {
      print('Checking payment status for transaction: $transactionId');

      // Update auth header before making the request
      await ApiService.instance.updateAuthHeader();

      final response = await ApiService.instance.get(
        'payments/ssl/status/$transactionId',
      );

              print('Payment status: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
              print('Error checking payment status: $e');
      throw Exception('Failed to check payment status: $e');
    }
  }

  // Poll payment status until completed
  static Future<Map<String, dynamic>> pollPaymentStatus({
    required String transactionId,
    int maxAttempts = 30, // 30 attempts with 2-second intervals = 1 minute
    int intervalSeconds = 2,
  }) async {
    print('Polling payment status for transaction: $transactionId');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final status = await checkPaymentStatus(transactionId: transactionId);
        
        if (status['payment'] != null) {
          final paymentStatus = status['payment']['status'];
          
          if (paymentStatus == 'completed') {
            print('Payment completed successfully');
            return status;
          } else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
                          print('Payment failed or cancelled');
            return status;
          }
        }

                  print('Payment still pending, attempt $attempt/$maxAttempts');
        
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: intervalSeconds));
        }
      } catch (e) {
        print('Error polling payment status: $e');
        if (attempt == maxAttempts) {
          throw Exception('Payment status polling failed: $e');
        }
        await Future.delayed(Duration(seconds: intervalSeconds));
      }
    }

    throw Exception('Payment status polling timed out');
  }
}

// WebView widget for SSLCommerz payment gateway
class SSLCommerzWebView extends StatefulWidget {
  final String gatewayUrl;
  final String transactionId;
  final Function(String) onSuccess;
  final Function(String) onFailure;
  final Function() onCancel;

  const SSLCommerzWebView({
    Key? key,
    required this.gatewayUrl,
    required this.transactionId,
    required this.onSuccess,
    required this.onFailure,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SSLCommerzWebView> createState() => _SSLCommerzWebViewState();
}

class _SSLCommerzWebViewState extends State<SSLCommerzWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            print('🌐 WebView page started: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('WebView page finished: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');
            
            // Handle success URL
            if (request.url.contains('payment-success')) {
              widget.onSuccess(widget.transactionId);
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            
            // Handle failure URL
            if (request.url.contains('payment-failed')) {
              widget.onFailure('Payment failed');
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            
            // Handle cancel URL
            if (request.url.contains('payment-cancelled')) {
              widget.onCancel();
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.gatewayUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
        ],
      ),
    );
  }
}

// Payment result handler
class PaymentResultHandler {
  static void handlePaymentSuccess(BuildContext context, String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 8),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction ID: $transactionId',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment has been processed successfully!',
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close WebView
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static void handlePaymentFailure(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            const Text(
              'Payment Failed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please try again or contact support if the issue persists.',
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static void handlePaymentCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(width: 8),
            const Text(
              'Payment Cancelled',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You cancelled the payment process.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can try again anytime.',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 