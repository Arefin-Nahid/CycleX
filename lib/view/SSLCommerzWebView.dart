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

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startPaymentStatusPolling();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            print('🔍 WebView loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('✅ WebView loaded: $url');
            _handleCallbackUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');
            if (_handleCallbackUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.gatewayUrl));
  }

  bool _handleCallbackUrl(String url) {
    if (url.contains('/payments/ssl/success') ||
        url.contains('/payments/ssl/fail') ||
        url.contains('/payments/ssl/cancel')) {
      print('🔄 Callback URL detected: $url');
      bool isSuccess = url.contains('/success');
      _showPaymentResultDialog(isSuccess);
      return true;
    }
    return false;
  }

  void _startPaymentStatusPolling() {
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
        print('📊 Payment status poll: ${status['payment']['status']}');
        if (status['payment']['status'] == 'completed') {
          _paymentCompleted = true;
          timer.cancel();
          _showPaymentResultDialog(true);
        } else if (status['payment']['status'] == 'failed' ||
            status['payment']['status'] == 'cancelled') {
          _paymentCompleted = true;
          timer.cancel();
          _showPaymentResultDialog(false);
        }
      } catch (e) {
        print('❌ Error polling payment status: $e');
        // Don't show error to user, just continue polling
        // The payment might not be in database yet
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _showCloseConfirmationDialog();
          },
        ),
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
          WebViewWidget(controller: _webViewController),
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