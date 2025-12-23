import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  String id;
  String title;
  String category;
  String thumbnailUrl;
  List<Map<String, dynamic>> content; // Quan trọng: Chứa nội dung text + ảnh xen kẽ
  DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    required this.content,
    required this.createdAt,
  });

  // Chuyển từ dữ liệu Firebase về dạng Object của app
  factory Article.fromMap(Map<String, dynamic> map, String id) {
    return Article(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'Chung',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      content: List<Map<String, dynamic>>.from(map['content'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Chuyển từ Object app thành dạng Map để gửi lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}