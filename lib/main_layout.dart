import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final _dashboardKey = GlobalKey<DashboardContentState>();

  String _displayName = 'User';
  String? _profilePicturePath;

  static const String baseUrl =
      'https://engine01.fuzikapp.com';

  static const String mediaBaseUrl =
      'https://media05.fuzikapp.com';

  static const Map<String, String> _mediaHeaders = {
    'Referer': 'https://www.fuzikapp.com/',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String? _getProfileImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final cleanPath = path.trim();

    if (cleanPath == 'None' ||
        cleanPath.toLowerCase() == 'null' ||
        cleanPath.toLowerCase() == 'false') {
      return null;
    }

    if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    final normalizedPath = cleanPath.startsWith('/')
        ? cleanPath.substring(1)
        : cleanPath;

    return '$mediaBaseUrl/$normalizedPath';
  }

  Future<void> _loadProfile() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    try {
      final uri = Uri.parse(
        '$baseUrl/musician2_detail'
            '?email=${Uri.encodeComponent(user.email!)}',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      if (data is! List || data.isEmpty) {
        return;
      }

      final profile = data[0];

      final profilePic =
      profile['profile_pic']?.toString();

      if (!mounted) return;

      setState(() {
        final apiDisplayName =
        profile['display_name']
            ?.toString()
            .trim();

        _displayName =
        apiDisplayName != null &&
            apiDisplayName.isNotEmpty
            ? apiDisplayName
            : user.email!.split('@')[0];

        _profilePicturePath = profilePic;
      });
    } catch (e) {
      debugPrint(
        'MAIN PROFILE LOAD ERROR: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;

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
          _buildStatusBadge(
            isMobile ? 'PR' : 'PR waiting/∞',
            const Color(0xFF8AB4F8),
          ),

          const SizedBox(width: 8),

          _buildStatusBadge(
            isMobile ? 'FZ' : 'FZ waiting/200',
            const Color(0xFFFFD600),
          ),

          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: _buildProfileMenu(
              isMobile,
            ),
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

            UploadContent(
              isActive: _selectedIndex == 1,
              onUploadSuccess: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),

            InventoryContent(
              isActive: _selectedIndex == 2,
            ),

            const CollaborationContent(),

            const Wallet(),
          ],
        ),
      ),

      bottomNavigationBar:
      BottomNavigationBar(
        backgroundColor:
        const Color(0xFF121212),

        type:
        BottomNavigationBarType.fixed,

        selectedItemColor:
        const Color(0xFFFFD600),

        unselectedItemColor:
        Colors.white54,

        currentIndex: _selectedIndex,

        onTap: (index) {
          if (index == 0 && _selectedIndex != 0) {
            _dashboardKey.currentState?.refreshDashboard();
          }

          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.upload,
            ),
            label: 'Upload',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.grid_view,
            ),
            label: 'Inventory',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.people,
            ),
            label: 'Collab',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_balance_wallet_rounded,
            ),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
      String text,
      Color color,
      ) {
    return Center(
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu(
      bool isMobile,
      ) {
    final profileImageUrl =
    _getProfileImageUrl(
      _profilePicturePath,
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),

      color: const Color(0xFF1E1E1E),

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),

        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white24,
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration:
              const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              clipBehavior:
              Clip.antiAlias,

              child: profileImageUrl != null
                  ? Image.network(
                profileImageUrl,
                width: 28,
                height: 28,
                fit: BoxFit.cover,

                headers:
                _mediaHeaders,

                loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                    ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return const Center(
                    child:
                    SizedBox(
                      width: 12,
                      height: 12,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  );
                },

                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.white,
                  );
                },
              )
                  : const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),

            if (!isMobile)
              const SizedBox(width: 8),

            if (!isMobile)
              Text(
                _displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),

            const SizedBox(width: 4),

            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),

      onSelected: (value) async {
        if (value == 'profile') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const EditProfileScreen(),
            ),
          );

          await _loadProfile();
        }

        if (value == 'settings') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const ChangePasswordScreen(),
            ),
          );
        }

        if (value == 'logout') {
          await Supabase.instance.client.auth
              .signOut();

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const LoginScreen(),
            ),
                (route) => false,
          );
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