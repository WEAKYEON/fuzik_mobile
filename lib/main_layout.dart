import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';
import 'upload.dart';
import 'inventory.dart';
import 'collaboration.dart';
import 'login_screen.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'wallet.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; 
  String _displayName = 'User';
  
  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      _displayName = user.email!.split('@')[0].isNotEmpty 
          ? user.email!.split('@')[0] 
          : 'Thanat';
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          isMobile ? 'FZ' : 'FUZIK',
          style: const TextStyle(
            color: Color(0xFFFFD600),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          _buildStatusBadge(isMobile ? 'PR' : 'PR waiting/∞', const Color(0xFF8AB4F8)),
          const SizedBox(width: 8),
          _buildStatusBadge(isMobile ? 'FZ' : 'FZ waiting/200', const Color(0xFFFFD600)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildProfileMenu(isMobile),
          ),
        ],
      ),
      
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const DashboardContent(),
            UploadContent(isActive: _selectedIndex == 1),
            const InventoryContent(),
            const CollaborationContent(),
            const Wallet()
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFFD600),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Collab'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
        ],
      ),
    );
  }


  Widget _buildStatusBadge(String text, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProfileMenu(bool isMobile) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      color: const Color(0xFF1E1E1E),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            if (!isMobile) const SizedBox(width: 8),
            if (!isMobile) Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
          ],
        ),
      ),
      onSelected: (value) async {
        if (value == 'profile'){
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context)=> const EditProfileScreen(),
            ),
          );
        }

        if (value == 'settings'){
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context)=> const ChangePasswordScreen(),
              ),
          );
        }

        if (value == 'logout') {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}