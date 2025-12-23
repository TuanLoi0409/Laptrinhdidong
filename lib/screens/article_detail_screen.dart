import 'dart:convert'; // Thư viện giải mã
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> articleData;
  final String articleId;

  const ArticleDetailScreen({
    super.key,
    required this.articleData,
    required this.articleId,
  });

  // Hàm phụ trợ kiểm tra Base64
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
    final String title = articleData['title'] ?? "Không có tiêu đề";
    final String category = articleData['category'] ?? "Chung";
    final String thumbnailUrl = articleData['thumbnailUrl'] ?? "";
    final Timestamp? timestamp = articleData['createdAt'];
    final String dateStr = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : "";
    final List<dynamic> contentList = articleData['content'] ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: thumbnailUrl.isNotEmpty && isBase64(thumbnailUrl)
                  ? Image.memory(base64Decode(thumbnailUrl), fit: BoxFit.cover)
                  : Container(color: Colors.grey),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(dateStr, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Vòng lặp hiển thị nội dung
                  ...contentList.map((item) {
                    if (item['type'] == 'text') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          item['value'] ?? "",
                          style: const TextStyle(fontSize: 16, height: 1.6),
                          textAlign: TextAlign.justify,
                        ),
                      );
                    } else if (item['type'] == 'image') {
                      final String imgStr = item['value'] ?? "";
                      if (imgStr.isEmpty || !isBase64(imgStr)) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // Giải mã ảnh từ chuỗi Base64
                          child: Image.memory(
                            base64Decode(imgStr),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const SizedBox(height: 50, child: Center(child: Text("Lỗi hiển thị ảnh"))),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}