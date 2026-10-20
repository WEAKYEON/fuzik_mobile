import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _currentPasswordController =
  TextEditingController();
  final _newPasswordController =
  TextEditingController();
  final _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isPasswordTooShort {
    final password =
        _newPasswordController.text;

    return password.isNotEmpty &&
        password.length < 6;
  }

  bool get _isPasswordMismatch {
    final password =
        _newPasswordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    return password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        confirmPassword.length >= password.length &&
        password != confirmPassword;
  }

  bool get _isFormValid {
    return _currentPasswordController
        .text
        .isNotEmpty &&
        _newPasswordController.text.length >= 6 &&
        _confirmPasswordController
            .text
            .isNotEmpty &&
        _newPasswordController.text ==
            _confirmPasswordController.text;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _onFieldChanged(String value) {
    setState(() {});
  }

  Future<void> _changePassword() async {
    if (!_isFormValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser =
          Supabase.instance.client.auth.currentUser;

      if (currentUser == null ||
          currentUser.email == null) {
        throw Exception(
          'User is not logged in.',
        );
      }

      // Verify current password first
      await Supabase.instance.client.auth
          .signInWithPassword(
        email: currentUser.email!,
        password:
        _currentPasswordController.text,
      );

      // Update to new password
      await Supabase.instance.client.auth
          .updateUser(
        UserAttributes(
          password:
          _newPasswordController.text,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: ${e.message}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString()}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Color(0xFFFFD600),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.45,
              ),
            ),
          ),

          // Change password form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              child: Container(
                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.7,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,

                  children: [
                    const Text(
                      'Change Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Current Password
                    _buildLabel(
                      'Current Password',
                    ),

                    _buildInput(
                      _currentPasswordController,
                      'Enter your current password',
                      obscure:
                      _obscureCurrentPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureCurrentPassword =
                          !_obscureCurrentPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // New Password
                    _buildLabel(
                      'New Password',
                    ),

                    _buildInput(
                      _newPasswordController,
                      'Enter your new password',
                      obscure:
                      _obscureNewPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureNewPassword =
                          !_obscureNewPassword;
                        });
                      },
                    ),

                    if (_isPasswordTooShort)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 8,
                        ),
                        child: Text(
                          'Password must be at least 6 characters',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Confirm New Password
                    _buildLabel(
                      'Confirm New Password',
                    ),

                    _buildInput(
                      _confirmPasswordController,
                      'Confirm your new password',
                      obscure:
                      _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),

                    if (_isPasswordMismatch)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 8,
                        ),
                        child: Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Change Password button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          8,
                        ),

                        boxShadow:
                        _isFormValid &&
                            !_isLoading
                            ? [
                          BoxShadow(
                            color:
                            const Color(
                              0xFFFFD600,
                            ).withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                            : [],
                      ),

                      child: ElevatedButton(
                        onPressed:
                        _isFormValid &&
                            !_isLoading
                            ? _changePassword
                            : null,

                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFFFFD600,
                          ),

                          disabledBackgroundColor:
                          Colors.grey.shade400,

                          minimumSize:
                          const Size(
                            double.infinity,
                            50,
                          ),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              8,
                            ),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                          CircularProgressIndicator(
                            color:
                            Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Change Password',
                          style: TextStyle(
                            color:
                            Colors.black,
                            fontWeight:
                            FontWeight.bold,
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
      padding: const EdgeInsets.only(
        bottom: 8,
      ),

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
        VoidCallback? onToggleVisibility,
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
        fillColor: const Color(
          0xFFF4F7FC,
        ),

        suffixIcon:
        onToggleVisibility != null
            ? IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed:
          onToggleVisibility,
        )
            : null,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}