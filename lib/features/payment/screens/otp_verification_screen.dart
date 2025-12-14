import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/theme.dart';
import '../../../core/utils/helpers.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _supabase = Supabase.instance.client;
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Please enter pin', isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: _otpController.text.trim(),
      );

      if (mounted) {
        Helpers.showSnackBar(context, 'OTP verified successfully!');
        Navigator.pop(context, true); // Return true on success
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        Helpers.showSnackBar(context, 'Invalid OTP. Please try again.', isError: true);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      await _supabase.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: null,
      );

      if (mounted) {
        Helpers.showSnackBar(context, 'New OTP sent to ${widget.email}');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to resend OTP', isError: true);
      }
    } finally {
      setState(() => _isResending = false);
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
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Verify OTP',
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

                      // Icon
                      Icon(
                        Icons.mail_outline,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),

                      SizedBox(height: 24),

                      // Instructions
                      Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 12),

                      Text(
                        'We sent a 6-digit code to\n${widget.email}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 32),

                      // OTP Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                hintText: '000000',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyOTP,
                                child: _isVerifying
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Verify',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Resend OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive code? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: _isResending ? null : _resendOTP,
                            child: _isResending
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Resend',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                          ),
                        ],
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