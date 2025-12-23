import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditArticleScreen extends StatefulWidget {
  // Thêm 2 tham số này để nhận dữ liệu cần sửa
  final Map<String, dynamic>? existingData;
  final String? docId;

  const AddEditArticleScreen({super.key, this.existingData, this.docId});

  @override
  State<AddEditArticleScreen> createState() => _AddEditArticleScreenState();
}

class _AddEditArticleScreenState extends State<AddEditArticleScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedCategory = 'Công nghệ';
  final List<String> _categories = ['Công nghệ', 'Thể thao', 'Đời sống', 'Giáo dục'];
  
  // Dùng dynamic để chứa: File (ảnh mới chọn) HOẶC String (ảnh cũ Base64)
  dynamic _thumbnailData; 
  final List<Map<String, dynamic>> _contentList = [];
  bool _isLoading = false;
  bool _isPickingImage = false; // Flag để tránh gọi image picker nhiều lần

  @override
  void initState() {
    super.initState();
    // Nếu có dữ liệu cũ (Tức là đang Sửa), thì điền vào form
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _titleController.text = data['title'] ?? '';
    if (_categories.contains(data['category'])) {
      _selectedCategory = data['category'];
    }
    
    // Load ảnh bìa (Là chuỗi Base64)
    if (data['thumbnailUrl'] != null) {
      _thumbnailData = data['thumbnailUrl']; 
    }

    // Load nội dung
    final List<dynamic> content = data['content'] ?? [];
    for (var item in content) {
      if (item['type'] == 'text') {
        _contentList.add({
          'type': 'text',
          'controller': TextEditingController(text: item['value']), // Điền chữ cũ vào
        });
      } else if (item['type'] == 'image') {
        _contentList.add({
          'type': 'image',
          'value': item['value'], // Đây là chuỗi Base64 cũ
        });
      }
    }
  }

  Future<void> _pickImage(bool isThumbnail, [int? index]) async {
    // Nếu đang pick, bỏ qua
    if (_isPickingImage) return;
    
    _isPickingImage = true;
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isThumbnail) {
            _thumbnailData = File(pickedFile.path); // Lưu File mới
          } else {
            _contentList.add({
              'type': 'image',
              'value': File(pickedFile.path), // Lưu File mới
            });
          }
        });
      }
    } catch (e) {
      print('Lỗi pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _addTextBlock() {
    setState(() {
      _contentList.add({
        'type': 'text',
        'controller': TextEditingController(),
      });
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _contentList.removeAt(index);
    });
  }

  // Hàm chuyển đổi thông minh:
  // - Nếu là File (ảnh mới) -> Nén thành Base64
  // - Nếu là String (ảnh cũ) -> Giữ nguyên
  Future<String> _processImage(dynamic imageData) async {
    if (imageData is File) {
      List<int> imageBytes = await imageData.readAsBytes();
      return base64Encode(imageBytes);
    } else if (imageData is String) {
      return imageData;
    }
    return "";
  }

  Future<void> _saveArticle() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa nhập tiêu đề!")));
      return;
    }
    if (_thumbnailData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa chọn ảnh bìa!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Xử lý ảnh bìa
      String thumbnailBase64 = await _processImage(_thumbnailData);

      // 2. Xử lý nội dung
      List<Map<String, dynamic>> finalContentToSave = [];
      for (var item in _contentList) {
        if (item['type'] == 'text') {
          finalContentToSave.add({
            'type': 'text',
            'value': (item['controller'] as TextEditingController).text,
          });
        } else if (item['type'] == 'image') {
          String imageBase64 = await _processImage(item['value']);
          finalContentToSave.add({
            'type': 'image',
            'value': imageBase64, 
          });
        }
      }

      Map<String, dynamic> articleData = {
        'title': _titleController.text,
        'category': _selectedCategory,
        'thumbnailUrl': thumbnailBase64,
        'content': finalContentToSave,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Kiểm tra: Nếu có docId -> Update, ngược lại -> Add
      if (widget.docId != null) {
        await FirebaseFirestore.instance.collection('articles').doc(widget.docId).update(articleData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
      } else {
        articleData['createdAt'] = FieldValue.serverTimestamp(); // Chỉ thêm ngày tạo nếu là bài mới
        await FirebaseFirestore.instance.collection('articles').add(articleData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng bài mới thành công!")));
      }

      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      print("Lỗi: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị ảnh (Cho cả File và Base64)
  Widget _buildImageWidget(dynamic imageData) {
    if (imageData is File) {
      return Image.file(imageData, width: double.infinity, fit: BoxFit.cover);
    } else if (imageData is String) {
      try {
        return Image.memory(base64Decode(imageData), width: double.infinity, fit: BoxFit.cover);
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image));
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? "Tạo bài viết mới" : "Chỉnh sửa bài viết"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveArticle,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề bài báo', border: OutlineInputBorder()),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Chủ đề', border: OutlineInputBorder()),
                  items: _categories.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    height: 150, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _thumbnailData == null
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text("Chọn ảnh bìa")])
                        : _buildImageWidget(_thumbnailData),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                const Text("Nội dung bài viết:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _contentList.length,
                  itemBuilder: (context, index) {
                    final item = _contentList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Stack(
                        children: [
                          item['type'] == 'text'
                              ? TextField(
                                  controller: item['controller'],
                                  maxLines: null,
                                  decoration: InputDecoration(hintText: 'Đoạn văn ${index + 1}...', border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8), 
                                  child: _buildImageWidget(item['value'])
                                ),
                          Positioned(top: 0, right: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeBlock(index))),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(onPressed: _addTextBlock, icon: const Icon(Icons.text_fields), label: const Text("Thêm chữ")),
                    ElevatedButton.icon(onPressed: () => _pickImage(false), icon: const Icon(Icons.image), label: const Text("Thêm ảnh")),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }
}