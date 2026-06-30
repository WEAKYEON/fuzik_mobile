import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_layout.dart'; 
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.signedOut) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => LoginScreen())
      );
    }
  });
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // เช็กว่ามีเซสชันค้างอยู่ไหม
    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (session != null) {
      // มีคนล็อกอินอยู่ -> ไปหน้าหลัก
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
    } else {
      // ไม่มีใครล็อกอิน -> ไปหน้า Login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // หน้าจอ Loading สีดำ หมุนๆ สีเหลือง ระหว่างเช็กสถานะ
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD600)),
      ),
    );
  }
}