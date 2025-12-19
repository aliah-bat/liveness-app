import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/config/theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/config/routes.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  
  // Lockout mechanism
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  
  static const int _maxAttempts = 3;
  static const int _lockoutDuration = 300;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockoutTimer() {
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = _lockoutDuration;
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _lockoutSeconds--;
      });

      if (_lockoutSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _failedAttempts = 0;
        });
      }
    });
  }

  Future<void> _handleSignIn() async {
    if (_isLockedOut) {
      Helpers.showSnackBar(
        context,
        'Account locked. Wait $_lockoutSeconds seconds.',
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    Helpers.hideKeyboard(context);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _failedAttempts = 0;
      Helpers.showSnackBar(context, AppConstants.signInSuccess);
      Navigator.pushReplacementNamed(context, AppConstants.dashboardRoute);
    } else {
      _failedAttempts++;
      
      if (_failedAttempts >= _maxAttempts) {
        _startLockoutTimer();
        Helpers.showSnackBar(
          context,
          'Too many failed attempts. Locked for $_lockoutDuration seconds.',
          isError: true,
        );
      } else {
        int remaining = _maxAttempts - _failedAttempts;
        Helpers.showSnackBar(
          context,
          '${authProvider.errorMessage ?? AppConstants.authError}. $remaining attempt(s) left.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                Text(
                  'BillPay',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Lockout warning banner
                if (_isLockedOut)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Account locked. Try again in $_lockoutSeconds seconds.',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _emailController,
                  enabled: !_isLockedOut,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLockedOut,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: Validators.validatePassword,
                  onFieldSubmitted: (_) => _handleSignIn(),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (isLoading || _isLockedOut) ? null : _handleSignIn,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isLockedOut ? 'Locked ($_lockoutSeconds s)' : 'Sign In',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                /* Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLockedOut ? null : () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),*/

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppConstants.signUpRoute);
                      },
                      child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}