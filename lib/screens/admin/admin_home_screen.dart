import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_edit_article_screen.dart';
import '../article_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/logout_button.dart'; 

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Hàm xóa (Giữ nguyên)
  void _deleteArticle(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa bài viết này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('articles').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa bài viết")));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Hàm chuyển sang trang Sửa
  void _editArticle(BuildContext context, Map<String, dynamic> data, String docId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditArticleScreen(
          existingData: data, // Truyền dữ liệu cũ sang
          docId: docId,       // Truyền ID sang để biết là đang update
        ),
      ),
    );
    if (result == true) setState(() {});
  }

  bool isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍💼 Quản Trị Viên"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LogoutButton(
              backgroundColor: Colors.red.shade800,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có bài viết nào."));
          }

          final documents = streamSnapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (ctx, index) {
              final data = documents[index].data() as Map<String, dynamic>;
              final docId = documents[index].id;
              
              final Timestamp? timestamp = data['createdAt'];
              final String dateStr = timestamp != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()) 
                  : "Vừa xong";
              
              String thumbnailStr = data['thumbnailUrl'] ?? "";

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: thumbnailStr.isNotEmpty && isBase64(thumbnailStr)
                      ? Image.memory(base64Decode(thumbnailStr), width: 80, fit: BoxFit.cover)
                      : const SizedBox(width: 80, child: Icon(Icons.image_not_supported)),
                  
                  title: Text(data['title'] ?? "Không tiêu đề", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['category']} • $dateStr"),
                  
                  // --- CẬP NHẬT PHẦN NÚT BẤM (TRAILING) ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Để Row chỉ chiếm diện tích vừa đủ
                    children: [
                      // Nút Sửa (Màu xanh)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editArticle(context, data, docId),
                      ),
                      // Nút Xóa (Màu đỏ)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteArticle(context, docId),
                      ),
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(articleData: data, articleId: docId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AddEditArticleScreen())
          );
          if (result == true) setState(() {});
        },
      ),
    );
  }
}