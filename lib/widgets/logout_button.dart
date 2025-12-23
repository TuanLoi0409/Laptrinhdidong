import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login/login_screen.dart';

/// Button đăng xuất
class LogoutButton extends StatefulWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const LogoutButton({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    // Hiện dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng Xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng Xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().logout();
      
      if (!mounted) return;

      // Quay về LoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã đăng xuất'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleLogout,
      icon: const Icon(Icons.logout),
      label: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Đăng Xuất'),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? Colors.red,
        foregroundColor: widget.textColor ?? Colors.white,
      ),
    );
  }
}

/// AppBar với logout button
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final bool showLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor = const Color.fromARGB(255, 33, 150, 243),
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      elevation: 0,
      actions: showLogout
          ? [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LogoutButton(
                  backgroundColor: Colors.red.shade600,
                  textColor: Colors.white,
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Drawer menu với logout
class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userRole;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue.shade600,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
            ),
          ),

          // Role badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: userRole == 'admin'
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: userRole == 'admin'
                    ? Colors.red.shade400
                    : Colors.green.shade400,
              ),
            ),
            child: Text(
              userRole == 'admin' ? '👨‍💼 Admin' : '👤 User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: userRole == 'admin'
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ),
          ),

          const Divider(),

          // Menu items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Trang Chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài Đặt'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ Giúp'),
            onTap: () => Navigator.pop(context),
          ),

          const Spacer(),
          const Divider(),

          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: LogoutButton(
                backgroundColor: Colors.red.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
