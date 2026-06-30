import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';
import 'upload.dart';
import 'inventory.dart';
import 'collaboration.dart';
import 'login_screen.dart';

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
    double sidebarWidth = isMobile ? 70 : 200;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar
            Container(
              width: sidebarWidth,
              color: Colors.black,
              child: Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                    child: Text(
                      isMobile ? 'FZ' : 'FUZIK',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.dashboard, 'Dashboard', index: 0, isMobile: isMobile),
                  _buildMenuItem(Icons.upload, 'Upload', index: 1, isMobile: isMobile),
                  _buildMenuItem(Icons.grid_view, 'Your inventory', index: 2, isMobile: isMobile),
                  _buildMenuItem(Icons.people, 'Collaboration', index: 3, isMobile: isMobile),
                ],
              ),
            ),
            Container(width: 1, color: Colors.white24),
            // Right Side
            Expanded(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatusBadge(isMobile ? 'PR' : 'PR waiting/∞', const Color(0xFF8AB4F8)),
                          const SizedBox(width: 8),
                          _buildStatusBadge(isMobile ? 'FZ' : 'FZ waiting/200', const Color(0xFFFFD600)),
                          const SizedBox(width: 8),
                          // 🌟 ปุ่ม Logout / Profile Menu
                          PopupMenuButton<String>(
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
                                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await Supabase.instance.client.auth.signOut();
                                
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginScreen()),
                                    (route) => false, 
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        const DashboardContent(),
                        UploadContent(isActive: _selectedIndex == 1),
                        const InventoryContent(),
                        const CollaborationContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {required int index, required bool isMobile}) {
    final isActive = _selectedIndex == index;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 24),
                if (!isMobile) const SizedBox(width: 16),
                if (!isMobile) Expanded(child: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}