import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../widgets/logout_button.dart';
import '../article_detail_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  bool isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _getContentText(dynamic content) {
    if (content == null) {
      return 'Không có nội dung';
    }
    // Nếu là String
    if (content is String) {
      return content;
    }
    // Nếu là Map {type: 'text', value: '...'}
    if (content is Map) {
      return content['value']?.toString() ?? 'Không có nội dung';
    }
    // Nếu là List
    if (content is List) {
      if (content.isEmpty) return 'Không có nội dung';
      
      var firstItem = content.first;
      if (firstItem is Map) {
        return firstItem['value']?.toString() ?? 'Không có nội dung';
      }
      return firstItem.toString();
    }
    return content.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👤 Tin tức hôm nay"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LogoutButton(
              backgroundColor: Colors.blue.shade800,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('articles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("Chưa có bài viết nào"),
                  Text("(Vui lòng quay lại sau)", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
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
                      : Container(width: 80, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                  title: Text(
                    data['title'] ?? 'Không có tiêu đề',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getContentText(data['content']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          articleData: data,
                          articleId: docId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}