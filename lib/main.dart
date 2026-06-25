import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // คำสั่งนี้ต้องมีเพื่อให้ Flutter เตรียมระบบก่อนเชื่อมต่อ
  WidgetsFlutterBinding.ensureInitialized();

  // ตั้งค่าเชื่อมต่อ Supabase ด้วย URL และ Key ของ Fuzik
  await Supabase.initialize(
    url: 'https://qrmgkhtdtommzqpmfolv.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybWdraHRkdG9tbXpxcG1mb2x2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTg4OTAzNTMsImV4cCI6MjAxNDQ2NjM1M30.kFseXZGODqx1wXiXXG4OB4ZXZ5cX32WA3_sm8NLDccQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzik App',
      debugShowCheckedModeBanner: false, // เอาป้ายแบนเนอร์ Debug มุมขวาบนออก
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // เปลี่ยนสีหลักให้ตรงกับเว็บได้
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// โครงสร้างหน้า Login (แบบมี UI และระบบเชื่อมต่อ Supabase)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // สร้างตัวแปรสำหรับเก็บค่าที่พิมพ์ในช่อง Email และ Password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // ตัวแปรเช็คสถานะว่ากำลังโหลดข้อมูลอยู่หรือไม่
  bool _isLoading = false;

  // ฟังก์ชันสำหรับกดปุ่มเข้าสู่ระบบ
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true; // เริ่มแสดงตัวโหลด
    });

    try {
      // เรียกใช้คำสั่งล็อกอินของ Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ถ้าล็อกอินสำเร็จ (ไม่มี Error) ให้แสดงข้อความแจ้งเตือนด้านล่าง
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าสู่ระบบสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      // ดักจับ Error จาก Supabase (เช่น รหัสผิด, ไม่มีอีเมลนี้)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ดักจับ Error อื่นๆ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // ปิดตัวโหลด
        });
      }
    }
  }

  @override
  void dispose() {
    // คืนค่าหน่วยความจำเมื่อปิดหน้าจอ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // สีพื้นหลังหน้าจอ
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400), // จำกัดความกว้างของฟอร์ม
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Fuzik Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ช่องกรอก Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ช่องกรอก Password
                  TextField(
                    controller: _passwordController,
                    obscureText: true, // ซ่อนรหัสผ่านเป็นจุด
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ปุ่ม Login
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}