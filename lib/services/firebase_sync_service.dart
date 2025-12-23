import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';

/// Service để tự động đồng bộ dữ liệu lên Firebase
class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  
  // Biến control tự động sync
  bool _autoSyncEnabled = true;
  int _syncIntervalSeconds = 30; // Mặc định 30 giây
  Timer? _syncTimer;
  
  // Queue dữ liệu chờ đẩy lên
  final List<Map<String, dynamic>> _pendingData = [];
  
  // Callback khi sync thành công/lỗi
  Function(String message)? onSyncSuccess;
  Function(String error)? onSyncError;

  FirebaseSyncService._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  factory FirebaseSyncService() {
    return _instance;
  }

  /// Khởi động auto-sync
  void startAutoSync({int intervalSeconds = 30}) {
    if (_syncTimer != null) {
      print('⚠️  Auto-sync đã chạy rồi');
      return;
    }
    
    _syncIntervalSeconds = intervalSeconds;
    _autoSyncEnabled = true;
    
    print('✅ Bắt đầu auto-sync mỗi $intervalSeconds giây');
    
    // Sync ngay lần đầu
    _performSync();
    
    // Lập lịch sync định kỳ
    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _performSync();
    });
  }

  /// Dừng auto-sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _autoSyncEnabled = false;
    print('🛑 Dừng auto-sync');
  }

  /// Đồng bộ ngay lập tức (không chờ interval)
  Future<void> syncNow() async {
    print('🔄 Sync ngay bây giờ...');
    await _performSync();
  }

  /// Thực hiện sync
  Future<void> _performSync() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('⚠️  Không có user đăng nhập, bỏ qua sync');
        return;
      }

      // Sync pending data
      if (_pendingData.isNotEmpty) {
        print('📤 Đẩy ${_pendingData.length} dữ liệu chờ lên Firebase...');
        
        for (var item in List.from(_pendingData)) {
          await _uploadDataToFirebase(item);
          _pendingData.remove(item);
        }
      } else {
        print('✓ Không có dữ liệu cần đẩy lên');
      }
    } catch (e) {
      print('❌ Lỗi sync: $e');
      onSyncError?.call('Lỗi đồng bộ: ${e.toString()}');
    }
  }

  /// Thêm dữ liệu vào queue (sẽ đẩy lên Firebase sau)
  void addDataToSync({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    DateTime? timestamp,
  }) {
    final syncItem = {
      'collection': collection,
      'docId': docId,
      'data': data,
      'timestamp': timestamp ?? DateTime.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
    };
    
    _pendingData.add(syncItem);
    print('📝 Thêm dữ liệu vào queue (${_pendingData.length} items)');
    
    // Nếu auto-sync bị tắt, tự động sync ngay
    if (!_autoSyncEnabled) {
      syncNow();
    }
  }

  /// Đẩy dữ liệu lên Firebase
  Future<void> _uploadDataToFirebase(Map<String, dynamic> item) async {
    try {
      String collection = item['collection'];
      String docId = item['docId'];
      Map<String, dynamic> data = item['data'];
      
      // Thêm metadata
      data['lastUpdated'] = FieldValue.serverTimestamp();
      data['syncedBy'] = item['userId'];
      
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: true));
      
      print('✅ Đã đẩy: $collection/$docId');
      onSyncSuccess?.call('Đã lưu: $collection');
    } catch (e) {
      print('❌ Lỗi đẩy dữ liệu: $e');
      throw e;
    }
  }

  /// Tạo article mới
  Future<void> createArticle({
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    bool autoUpload = true,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Không có user đăng nhập');
      
      String articleId = _firestore.collection('articles').doc().id;
      
      Map<String, dynamic> articleData = {
        'id': articleId,
        'title': title,
        'content': content,
        'category': category,
        'imageUrl': imageUrl ?? '',
        'authorId': currentUser.uid,
        'authorEmail': currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
        'views': 0,
        'likes': 0,
      };
      
      if (autoUpload) {
        // Đẩy lên Firebase ngay
        await _firestore
            .collection('articles')
            .doc(articleId)
            .set(articleData);
        print('✅ Article được tạo và lưu: $articleId');
        onSyncSuccess?.call('Article lưu thành công');
      } else {
        // Thêm vào queue
        addDataToSync(
          collection: 'articles',
          docId: articleId,
          data: articleData,
        );
        print('📝 Article được thêm vào queue: $articleId');
      }
    } catch (e) {
      print('❌ Lỗi tạo article: $e');
      onSyncError?.call('Lỗi: ${e.toString()}');
      rethrow;
    }
  }

  /// Cập nhật article
  Future<void> updateArticle({
    required String articleId,
    required Map<String, dynamic> updates,
    bool autoUpload = true,
  }) async {
    try {
      updates['lastUpdated'] = FieldValue.serverTimestamp();
      
      if (autoUpload) {
        await _firestore
            .collection('articles')
            .doc(articleId)
            .update(updates);
        print('✅ Article cập nhật: $articleId');
        onSyncSuccess?.call('Article cập nhật thành công');
      } else {
        addDataToSync(
          collection: 'articles',
          docId: articleId,
          data: updates,
        );
      }
    } catch (e) {
      print('❌ Lỗi cập nhật article: $e');
      onSyncError?.call('Lỗi: ${e.toString()}');
      rethrow;
    }
  }

  /// Xóa article
  Future<void> deleteArticle(String articleId) async {
    try {
      await _firestore.collection('articles').doc(articleId).delete();
      print('✅ Article đã xóa: $articleId');
      onSyncSuccess?.call('Article đã xóa');
    } catch (e) {
      print('❌ Lỗi xóa article: $e');
      onSyncError?.call('Lỗi: ${e.toString()}');
      rethrow;
    }
  }

  /// Lấy số dữ liệu chờ đẩy
  int getPendingDataCount() => _pendingData.length;

  /// Lấy trạng thái auto-sync
  bool isAutoSyncEnabled() => _autoSyncEnabled;

  /// Lấy interval hiện tại
  int getSyncInterval() => _syncIntervalSeconds;

  /// Đặt interval mới
  void setSyncInterval(int seconds) {
    if (_syncTimer != null) {
      stopAutoSync();
      startAutoSync(intervalSeconds: seconds);
    }
  }

  /// Xóa tất cả dữ liệu chờ
  void clearPendingData() {
    _pendingData.clear();
    print('🗑️  Xóa tất cả dữ liệu chờ');
  }

  /// Lấy danh sách dữ liệu chờ
  List<Map<String, dynamic>> getPendingData() => List.from(_pendingData);

  /// Dừng service
  void dispose() {
    stopAutoSync();
    _pendingData.clear();
    print('🔌 Firebase Sync Service đã dừng');
  }
}
