import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _genreController = TextEditingController();
  final _instrumentController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isPasswordTooShort {
    final password = _passwordController.text;

    return password.isNotEmpty &&
        password.length < 6;
  }

  bool get _isPasswordMismatch {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    return password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        confirmPassword.length >= password.length &&
        password != confirmPassword;
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text ==
            _confirmPasswordController.text &&
        _acceptTerms;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _genreController.dispose();
    _instrumentController.dispose();

    super.dispose();
  }

  void _onFieldChanged(String value) {
    setState(() {});
  }

  Future<void> _signUp() async {
    if (!_isFormValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse res =
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username':
          _usernameController.text.trim(),
        },
      );

      if (res.user != null) {
        try {
          final firstName =
          _firstNameController.text.trim();

          final lastName =
          _lastNameController.text.trim();

          final displayName =
          _usernameController.text.trim();

          final phone =
          _phoneController.text.trim();

          final email =
          _emailController.text.trim();

          final genre =
          _genreController.text.trim();

          final instrument =
          _instrumentController.text.trim();

          final url = Uri.parse(
            'https://engine01.fuzikapp.com/create_musician2'
                '?display_name=${Uri.encodeComponent(displayName)}'
                '&email=${Uri.encodeComponent(email)}'
                '&first_name=${Uri.encodeComponent(firstName)}'
                '&last_name=${Uri.encodeComponent(lastName)}'
                '&genre=${Uri.encodeComponent(genre)}'
                '&instrument=${Uri.encodeComponent(instrument)}'
                '&tel=${Uri.encodeComponent(phone)}',
          );

          final response = await http.get(url);

          if (response.statusCode == 200 ||
              response.statusCode == 201) {
            debugPrint(
              'Profile created in Engine01 successfully.',
            );
          } else {
            debugPrint(
              'Failed to create Engine01 profile: '
                  '${response.statusCode} - ${response.body}',
            );
          }
        } catch (e) {
          debugPrint(
            'Engine01 API error: $e',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration Success! You can now login.',
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
          content: Text(e.message),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 80,
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.9,
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
                      'Register',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Create your account. It\'s free and only take a minute',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            _firstNameController,
                            'Firstname',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            _lastNameController,
                            'Lastname',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      _usernameController,
                      'Display name',
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      _phoneController,
                      'Telephone',
                      inputType:
                      TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      _emailController,
                      'Email',
                      inputType:
                      TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      _passwordController,
                      'Password',
                      obscure:
                      _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword =
                          !_obscurePassword;
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

                    const SizedBox(height: 16),

                    _buildInput(
                      _confirmPasswordController,
                      'Confirm Password',
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

                    const SizedBox(height: 16),

                    _buildInput(
                      _genreController,
                      'Music genre',
                    ),

                    const SizedBox(height: 16),

                    _buildInput(
                      _instrumentController,
                      'Musical instruments',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          activeColor:
                          const Color(
                            0xFFFFD600,
                          ),
                          checkColor:
                          Colors.black,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms =
                                  value ?? false;
                            });
                          },
                        ),

                        Expanded(
                          child: RichText(
                            text:
                            const TextSpan(
                              style: TextStyle(
                                color:
                                Colors.black,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                  'I accept the ',
                                ),
                                TextSpan(
                                  text:
                                  'Terms of Use',
                                  style:
                                  TextStyle(
                                    color:
                                    Color(
                                      0xFFB8860B,
                                    ),
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' & ',
                                ),
                                TextSpan(
                                  text:
                                  'Privacy Policy',
                                  style:
                                  TextStyle(
                                    color:
                                    Color(
                                      0xFFB8860B,
                                    ),
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                            blurRadius:
                            20,
                            spreadRadius:
                            2,
                          ),
                        ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed:
                        _isFormValid &&
                            !_isLoading
                            ? _signUp
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
                          'Register Now',
                          style: TextStyle(
                            color:
                            Colors.black,
                            fontWeight:
                            FontWeight
                                .bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Already have an account? ',
                            ),
                            TextSpan(
                              text: 'Login',
                              style: const TextStyle(
                                color: Color(0xFFD68910),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pop(context);
                                },
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


          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String hint, {
        bool obscure = false,
        TextInputType inputType =
            TextInputType.text,
        VoidCallback? onToggleVisibility,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      onChanged: _onFieldChanged,
      cursorColor: Colors.black,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.white,

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
          BorderRadius.circular(4),
          borderSide: const BorderSide(
            color: Colors.grey,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(4),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(4),
          borderSide:
          const BorderSide(
            color: Color(0xFF6C757D),
            width: 1.5,
          ),
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}