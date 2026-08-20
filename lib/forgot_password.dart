import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();

  bool get _isFormValid {
    final email = _emailController.text.trim();

    return email.isNotEmpty && email.contains('@');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email.');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    // Mockup only. supabase ps reset logic goes here

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset email will be sent.',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Forgot Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Enter your email address to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildLabel('Email'),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        setState(() {});
                      },
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Send Reset Email button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isFormValid
                            ? [
                          BoxShadow(
                            color: const Color(0xFFFFD600)
                                .withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed:
                        _isFormValid ? _sendResetEmail : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                          disabledBackgroundColor:
                          Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Send Reset Email',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back to Login
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Color(0xFFD68910),
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}