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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<DashboardContentState> _dashboardKey =
  GlobalKey<DashboardContentState>();
  int _selectedIndex = 0; 
  String _displayName = 'User';
  String _profilePic = '';
  
  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    print('Current user: $user'); // Debugging line to check the current user
    if (user != null && user.email != null) {
      print(user);
      _displayName = user.email!.split('@')[0].isNotEmpty 
          ? user.email!.split('@')[0] 
          : 'User';

      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/musician2_detail'
              '?email=${Uri.encodeComponent(user.email!)}',
        ),
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        final profilePic =
            data[0]['profile_pic']?.toString() ?? '';

        final displayName =
            data[0]['display_name']?.toString() ?? '';

        if (!mounted) return;

        setState(() {
          _profilePic = profilePic;

          //debugPrint('PROFILE PIC: $_profilePic');

          if (displayName.isNotEmpty) {
            _displayName = displayName;
          }
        });
      }
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
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
        title: Row(
          children: [
            Image.asset('assets/images/FuzikLogo.png', width: 35, height: 35,),
            SizedBox(width: 10,),
            Text(
              isMobile ? 'FZ' : 'FUZIK',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          _buildStatusBadge('FuzikPremiumCoin.png'),
          const SizedBox(width: 8),
          _buildStatusBadge('FuzikNormalCoin.png'),
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
            DashboardContent(
              key: _dashboardKey,
            ),
            UploadContent(isActive: _selectedIndex == 1),
             InventoryContent(isActive: _selectedIndex == 2,
          ),
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            _dashboardKey.currentState?.refreshDashboardData();
          }
        },
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


  Widget _buildStatusBadge(String imageUrl) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 42, 41, 41),
          borderRadius: BorderRadius.circular(25)
        ),
        child: Row(
          children: [
          Image.asset('assets/images/$imageUrl',width: 35,height: 35,),
          SizedBox(width: 5,),
          Text('200',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w900),)
          ]),
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
            ClipOval(
              child: Container(
                width: 24,
                height: 24,
                color: Colors.grey,
                child: _profilePic.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: _profilePic.startsWith('http')
                      ? _profilePic
                      : 'https://media05.fuzikapp.com/$_profilePic',
                  httpHeaders: const {
                    'Referer': 'https://fuzikapp.com',
                  },
                  fit: BoxFit.cover,
                  width: 24,
                  height: 24,
                  errorWidget: (context, url, error) {
                    return const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    );
                  },
                )
                    : const Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
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