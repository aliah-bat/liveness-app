import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bill/models/bill_model.dart';
import '../../auth/screens/face_verification_screen.dart';
import '../../../core/config/theme.dart';

class PaymentScreen extends StatefulWidget {
  final BillModel bill;

  const PaymentScreen({Key? key, required this.bill}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;
  bool _hasFaceRegistered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFaceRegistration();
  }

  Future<void> _checkFaceRegistration() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('users')
          .select('face_image_url')
          .eq('id', userId)
          .single();

      setState(() {
        _hasFaceRegistered = data['face_image_url'] != null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking face registration: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _proceedToPayment() async {
    if (_hasFaceRegistered) {
      // Use face verification
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaceVerificationScreen(billId: widget.bill.id),
        ),
      );

      if (verified == true) {
        _processPayment();
      }
    } else {
      // Fallback to password
      _showPasswordDialog();
    }
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your password to confirm payment'),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _verifyPassword(passwordController.text);
            },
            child: Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPassword(String password) async {
    try {
      setState(() => _isProcessing = true);

      final email = _supabase.auth.currentUser?.email;
      if (email == null) throw Exception('User not found');

      // Verify password by attempting sign in
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _processPayment();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password')),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processPayment() async {
    try {
      setState(() => _isProcessing = true);

      // Mark bill as paid
      await _supabase
          .from('bills')
          .update({'status': 'paid'})
          .eq('id', widget.bill.id);

      setState(() => _isProcessing = false);

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );

      Navigator.pop(context, true); // Return true to refresh dashboard
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildRow('Bill', widget.bill.title),
                  Divider(),
                  _buildRow('Amount', 'RM ${widget.bill.amount.toStringAsFixed(2)}'),
                  Divider(),
                  _buildRow('Due Date', _formatDate(widget.bill.dueDate)),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              _hasFaceRegistered 
                ? 'Face ID verification will be used'
                : 'Password verification will be used',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _proceedToPayment,
                child: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}