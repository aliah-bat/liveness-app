import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/screens/face_verification_screen.dart';
import 'otp_verification_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String billId;
  final String billTitle;
  final double billAmount;

  const PaymentScreen({
    super.key,
    required this.billId,
    required this.billTitle,
    required this.billAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
  setState(() => _isProcessing = true);

  try {
    // Step 1: Face Verification
    final faceVerified = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceVerificationScreen()),
    );

    if (faceVerified != true) {
      setState(() => _isProcessing = false);
      Helpers.showSnackBar(context, 'Face verification failed', isError: true);
      return;
    }

    // Step 2: Send OTP
    final userEmail = _supabase.auth.currentUser?.email;
    if (userEmail == null) {
      throw Exception('User email not found');
    }

    await _supabase.auth.signInWithOtp(
      email: userEmail,
      shouldCreateUser: false,  // Important - only for existing users
    );

    if (mounted) {
      Helpers.showSnackBar(context, 'Enter the 6-digit code sent to $userEmail');
    }

    // Step 3: OTP Verification
    final otpVerified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(email: userEmail),
      ),
    );

    if (otpVerified != true) {
      setState(() => _isProcessing = false);
      Helpers.showSnackBar(context, 'OTP verification failed', isError: true);
      return;
    }

    // Step 4: Process Payment
    await _processPayment();

    if (mounted) {
      Helpers.showSnackBar(context, 'Payment successful!');
      Navigator.pop(context, true);
    }

  } catch (e) {
    if (mounted) {
      Helpers.showSnackBar(context, 'Payment failed: $e', isError: true);
    }
  } finally {
    setState(() => _isProcessing = false);
  }
}

  Future<void> _processPayment() async {
  await Future.delayed(Duration(seconds: 2));
  
  final userId = _supabase.auth.currentUser?.id;
  if (userId != null) {
    // Insert payment record
    await _supabase.from('payments').insert({
      'user_id': userId,
      'bill_id': widget.billId,
      'bill_title': widget.billTitle,
      'amount': widget.billAmount,
      'payment_date': DateTime.now().toIso8601String(),
      'status': 'completed',
    });

    // Mark bill as paid
    await _supabase.from('bills').update({
      'status': 'paid',
    }).eq('id', widget.billId);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20),

                      // Bill details
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.billTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'RM ${widget.billAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Security info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Secured with Face ID + OTP verification',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Pay button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handlePayment,
                          child: _isProcessing
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock),
                                    SizedBox(width: 8),
                                    Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
}