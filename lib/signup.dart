import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool get _isPasswordMismatch {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    return password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password != confirmPassword;
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        !_isPasswordMismatch;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value) {
    setState(() {});
  }

  // 3. ฟังก์ชัน Backend สำหรับสมัคสมาชิก
  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // เก็บ Username แนบไปกับข้อมูลผู้ใช้ของ Supabase ด้วย
        data: {'username': _usernameController.text.trim()}, 
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Success! You can now login.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Signup form
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
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLabel('Username'),
                    _buildInput(
                      _usernameController,
                      'Enter your username',
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email'),
                    _buildInput(
                      _emailController,
                      'Enter your email',
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Password'),
                    _buildInput(
                      _passwordController,
                      'Enter your password',
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Confirm Password'),
                    _buildInput(
                      _confirmPasswordController,
                      'Confirm your password',
                      obscure: true,
                    ),
                    if (_isPasswordMismatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
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
                        onPressed: (_isFormValid && !_isLoading) ? _signUp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: _onFieldChanged,
      cursorColor: Colors.black,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }
}