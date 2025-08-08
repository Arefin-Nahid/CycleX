import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';

class SSLCommerzWebView extends StatefulWidget {
  final String gatewayUrl;
  final String transactionId;
  final double amount;
  final Function(bool success) onPaymentComplete;

  const SSLCommerzWebView({
    Key? key,
    required this.gatewayUrl,
    required this.transactionId,
    required this.amount,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<SSLCommerzWebView> createState() => _SSLCommerzWebViewState();
}

class _SSLCommerzWebViewState extends State<SSLCommerzWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  Timer? _statusPollingTimer;
  Timer? _timeoutTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 12; // 1 minute (12 * 5 seconds)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // Add a delay before starting polling to give backend time to create payment record
    Timer(const Duration(seconds: 3), () {
      _startPaymentStatusPolling();
    });
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    // Validate that the gateway URL is a proper SSLCommerz gateway URL
    if (!widget.gatewayUrl.contains('sslcommerz') && 
        !widget.gatewayUrl.contains('sandbox') &&
        !widget.gatewayUrl.contains('gateway')) {
              print('Warning: Gateway URL may not be a valid SSLCommerz URL: ${widget.gatewayUrl}');
    }
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null; // Clear any previous error messages
            });
            print('WebView loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
                          print('WebView loaded: $url');
            _handleCallbackUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');
            
            // Prevent loading of API endpoints that could return error messages
            if (request.url.contains('/api/') || 
                request.url.contains('/payments/ssl/status/') ||
                request.url.contains('payment-not-found') ||
                request.url.contains('error') ||
                request.url.contains('404') ||
                request.url.contains('500')) {
              print('Blocked navigation to potential error endpoint: ${request.url}');
              return NavigationDecision.prevent;
            }
            
            // Only allow navigation to SSLCommerz gateway URLs
            if (!request.url.contains('sslcommerz') && 
                !request.url.contains('sandbox') &&
                !request.url.contains('gateway') &&
                !request.url.contains('success') &&
                !request.url.contains('fail') &&
                !request.url.contains('cancel')) {
              print('Blocked navigation to non-gateway URL: ${request.url}');
              return NavigationDecision.prevent;
            }
            
            if (_handleCallbackUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            // Don't show error messages to user, just log them
            // This prevents backend error messages from being displayed
            
            // If the error contains JSON or backend error messages, prevent them from being displayed
            if (error.description.contains('{') || 
                error.description.contains('"message"') ||
                error.description.contains('Payment not found')) {
              print('Blocked backend error message from being displayed: ${error.description}');
              return;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.gatewayUrl));
  }

  bool _handleCallbackUrl(String url) {
    if (url.contains('/payments/ssl/success') ||
        url.contains('/payments/ssl/fail') ||
        url.contains('/payments/ssl/cancel')) {
      print('Callback URL detected: $url');
      bool isSuccess = url.contains('/success');
      
      // Update payment status on backend when callback is detected
      _updatePaymentStatusOnBackend(isSuccess ? 'completed' : 'failed');
      
      _showPaymentResultDialog(isSuccess);
      return true;
    }
    return false;
  }

  Future<void> _updatePaymentStatusOnBackend(String status) async {
    try {
      print('🔄 Updating payment status on backend: $status');
      
      final response = await ApiService.instance.post('payments/ssl/frontend-update', {
        'transactionId': widget.transactionId,
        'status': status,
        'paymentDetails': {
          'amount': widget.amount,
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'frontend_callback'
        }
      });
      
      print('✅ Payment status updated on backend: $response');
    } catch (e) {
      print('❌ Error updating payment status on backend: $e');
      // Don't show error to user, just log it
      // The payment might still be processed by SSLCommerz callbacks
    }
  }

  void _startPaymentStatusPolling() {
    // Clear any existing error messages before starting polling
    _clearErrorMessages();
    
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_paymentCompleted) {
        timer.cancel();
        return;
      }
      
      _pollingAttempts++;
      if (_pollingAttempts >= _maxPollingAttempts) {
        print('⏰ Payment status polling timeout');
        timer.cancel();
        return;
      }
      
      try {
        final status = await ApiService.checkSSLPaymentStatus(widget.transactionId);
        
        // Handle the response based on payment status
        if (status['payment'] != null) {
          final paymentStatus = status['payment']['status'];
          print('Payment status poll: $paymentStatus (attempt $_pollingAttempts/$_maxPollingAttempts)');
          
          if (paymentStatus == 'completed') {
            _paymentCompleted = true;
            timer.cancel();
            _showPaymentResultDialog(true);
          } else if (paymentStatus == 'failed' ||
              paymentStatus == 'cancelled') {
            _paymentCompleted = true;
            timer.cancel();
            _showPaymentResultDialog(false);
          } else if (paymentStatus == 'pending') {
            // Continue polling for pending payments
                          print('Payment still pending, continuing to poll...');
          } else {
            // Unknown status, continue polling
            print('❓ Unknown payment status: $paymentStatus, continuing to poll...');
          }
        } else {
          // No payment data in response, continue polling
                        print('No payment data available yet, continuing to poll...');
        }
      } catch (e) {
                  print('Error polling payment status: $e');
        // Don't show error to user, just continue polling
        // The payment might not be in database yet
        // This is expected behavior when payment is still being processed
      }
    });
  }

  void _showPaymentResultDialog(bool isSuccess) {
    if (!mounted) return; // Prevent showing dialog if widget is disposed
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess ? 'Payment Successful!' : 'Payment Failed',
                  style: TextStyle(
                    color: isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSuccess
                    ? 'Your payment of ৳${widget.amount.toStringAsFixed(2)} has been processed successfully.'
                    : 'Your payment could not be processed. Please try again.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'Transaction ID: ${widget.transactionId}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                // Then call the callback which will handle navigation
                if (mounted) {
                  widget.onPaymentComplete(isSuccess);
                }
              },
              child: Text(
                isSuccess ? 'Continue' : 'Try Again',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearErrorMessages() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _setErrorMessage(String message) {
    // Only set user-friendly error messages, not backend error responses
    if (!message.contains('{') && !message.contains('"') && !message.contains('message')) {
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _webViewController.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView with error handling
          WebViewWidget(controller: _webViewController),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Payment Gateway...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error message overlay (only for user-friendly messages, not backend errors)
          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCloseConfirmationDialog() {
    if (!mounted) return; // Prevent showing dialog if widget is disposed
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Cancel Payment?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text(
            'Are you sure you want to cancel this payment? Your transaction will be cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Continue Payment',
                style: TextStyle(color: Colors.teal, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                // Then call the callback which will handle navigation
                if (mounted) {
                  widget.onPaymentComplete(false);
                }
              },
              child: const Text(
                'Cancel Payment',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper function to launch SSLCommerz payment
Future<void> launchSSLCommerzPayment({
  required BuildContext context,
  required String gatewayUrl,
  required String transactionId,
  required double amount,
  required Function(bool success) onPaymentComplete,
}) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SSLCommerzWebView(
        gatewayUrl: gatewayUrl,
        transactionId: transactionId,
        amount: amount,
        onPaymentComplete: onPaymentComplete,
      ),
    ),
  );
}