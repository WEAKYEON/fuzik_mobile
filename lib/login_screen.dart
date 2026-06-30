import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Color(0xFFD6E33B), Color(0xFF0F0F0F)],
          ),
        ),
        child: Stack(
          children: [
            // 1. หัวข้อ FUZIK มุมซ้ายบน
            const Positioned(
              top: 50, left: 24,
              child: Text('FUZIK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
            ),
            // 2. กล่องขาวตรงกลาง
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Fuzik Collaboration Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 32),
                      _buildLabel('Email'),
                      _buildInput(_emailController, 'Enter Email...'),
                      const SizedBox(height: 20),
                      _buildLabel('Password'),
                      _buildInput(_passwordController, 'Enter Password...', obscure: true),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFD68910))))),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Sign up', style: TextStyle(color: Color(0xFFD68910))))),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD600), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Login', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));
  Widget _buildInput(TextEditingController controller, String hint, {bool obscure = false}) => TextField(
  controller: controller,
  obscureText: obscure,
  // 🌟 เพิ่ม cursorColor เพื่อให้รู้ว่ากำลังพิมพ์อยู่
  cursorColor: Colors.black, 
  // 🌟 เน้นสไตล์ตัวอักษรให้ชัดเจน
  style: const TextStyle(
    color: Colors.black87, 
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
    filled: true,
    fillColor: const Color(0xFFF4F7FC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    // เพิ่ม contentPadding ให้ตัวหนังสือไม่อยู่ชิดขอบเกินไป
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);
}