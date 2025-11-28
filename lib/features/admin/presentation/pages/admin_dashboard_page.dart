import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_management_page.dart';
import 'add_news_page.dart';
import 'news_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  int _totalNews = 0;
  int _totalUsers = 0;
  int _todayNews = 0;
  int _todayUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Lấy tổng số tin tức
      final newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .get();
      _totalNews = newsSnapshot.docs.length;

      // Lấy tin tức hôm nay
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayNewsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();
      _todayNews = todayNewsSnapshot.docs.length;

      // Lấy tổng số users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _totalUsers = usersSnapshot.docs.length;

      // Lấy users đăng ký hôm nay
      final todayUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();
      _todayUsers = todayUsersSnapshot.docs.length;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade900,
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 20),
                
                // Menu items
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildMenuItem(
                  icon: Icons.article_rounded,
                  title: 'Quản lý tin tức',
                  index: 1,
                ),
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  title: 'Quản lý users',
                  index: 2,
                ),
                _buildMenuItem(
                  icon: Icons.add_circle_rounded,
                  title: 'Thêm tin mới',
                  index: 3,
                ),
                
                const Spacer(),
                
                // Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildNewsManagement();
      case 2:
        return _buildUserManagement();
      case 3:
        return _buildAddNews();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng quan hệ thống',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadDashboardData,
                  tooltip: 'Làm mới',
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stats cards
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  title: 'Tổng tin tức',
                  value: _totalNews.toString(),
                  icon: Icons.article_rounded,
                  color: Colors.blue,
                  gradient: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                _buildStatCard(
                  title: 'Tin hôm nay',
                  value: _todayNews.toString(),
                  icon: Icons.today_rounded,
                  color: Colors.green,
                  gradient: [Colors.green.shade400, Colors.green.shade600],
                ),
                _buildStatCard(
                  title: 'Tổng users',
                  value: _totalUsers.toString(),
                  icon: Icons.people_rounded,
                  color: Colors.orange,
                  gradient: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                _buildStatCard(
                  title: 'User mới hôm nay',
                  value: _todayUsers.toString(),
                  icon: Icons.person_add_rounded,
                  color: Colors.purple,
                  gradient: [Colors.purple.shade400, Colors.purple.shade600],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Thêm tin mới',
                          color: Colors.blue,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                        _buildQuickActionButton(
                          icon: Icons.people_outline,
                          label: 'Xem users',
                          color: Colors.orange,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        _buildQuickActionButton(
                          icon: Icons.list_alt,
                          label: 'Danh sách tin',
                          color: Colors.green,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsManagement() {
    return const NewsManagementPage();
  }

  Widget _buildUserManagement() {
    return const UserManagementPage();
  }

  Widget _buildAddNews() {
    return const AddNewsPage();
  }
}
