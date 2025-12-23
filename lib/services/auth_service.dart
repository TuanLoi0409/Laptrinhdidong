import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service để quản lý xác thực và phân quyền
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  /// Lấy user hiện tại
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Kiểm tra xem user có phải admin không
  Future<bool> isAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      return doc.exists && doc['role'] == 'admin';
    } catch (e) {
      print('Lỗi kiểm tra admin: $e');
      return false;
    }
  }

  /// Lấy role của user
  Future<String?> getUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        return doc['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy role: $e');
      return null;
    }
  }

  /// Lấy thông tin user
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy thông tin user: $e');
      return null;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('✅ Đã đăng xuất');
    } catch (e) {
      print('❌ Lỗi đăng xuất: $e');
      rethrow;
    }
  }

  /// Stream để theo dõi trạng thái đăng nhập
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
