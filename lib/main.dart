import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_sync_service.dart';
import 'services/auth_service.dart';

// Thư viện Firebase

// Import 2 màn hình mà bạn đã tạo ở bước trước
// (Đảm bảo bạn đã tạo file đúng thư mục như hướng dẫn trước)
import 'screens/user/user_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/login/login_screen.dart';

void main() async {
  // 1. Đảm bảo Flutter Binding được khởi tạo trước khi gọi Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Khởi tạo Firebase
  // LƯU Ý QUAN TRỌNG: 
  // Nếu bạn CHƯA tải file google-services.json bỏ vào thư mục android/app,
  // hãy thêm dấu // vào đầu dòng bên dưới để comment nó lại (như ví dụ sau):
  // await Firebase.initializeApp(); 
  
  // Nếu đã có file json rồi thì bỏ dấu // đi:
  await Firebase.initializeApp();
  
  // 3. Khởi động Firebase Auto Sync (cập nhật mỗi 30 giây)
  FirebaseSyncService().startAutoSync(intervalSeconds: 30);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Đọc Báo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Nếu không có user đăng nhập, hiển thị LoginScreen
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          // Nếu có user, kiểm tra role và điều hướng tương ứng
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Kiểm tra role
              String? role = roleSnapshot.data;
              
              if (role == 'admin') {
                return const AdminHomeScreen();
              } else {
                return const UserHomeScreen();
              }
            },
          );
        },
      ),
    );
  }
}