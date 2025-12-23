import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';

/// Widget hiển thị trạng thái sync và điều khiển
class SyncControlPanel extends StatefulWidget {
  const SyncControlPanel({super.key});

  @override
  State<SyncControlPanel> createState() => _SyncControlPanelState();
}

class _SyncControlPanelState extends State<SyncControlPanel> {
  final FirebaseSyncService _syncService = FirebaseSyncService();
  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(
      text: _syncService.getSyncInterval().toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            Row(
              children: [
                const Icon(Icons.cloud_sync, color: Colors.blue),
                const SizedBox(width: 10),
                const Text(
                  'Firebase Auto Sync',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Trạng thái
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _syncService.isAutoSyncEnabled()
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _syncService.isAutoSyncEnabled()
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: _syncService.isAutoSyncEnabled()
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _syncService.isAutoSyncEnabled()
                          ? 'Auto Sync: BẬT'
                          : 'Auto Sync: TẮT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${_syncService.getPendingDataCount()} pending',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Interval control
            Text(
              'Khoảng cập nhật (giây):',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _updateInterval,
                  icon: const Icon(Icons.save),
                  label: const Text('Đặt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleAutoSync,
                    icon: Icon(
                      _syncService.isAutoSyncEnabled()
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      _syncService.isAutoSyncEnabled() ? 'Tạm dừng' : 'Tiếp tục',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _syncService.isAutoSyncEnabled()
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncNow,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Sync Ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearPending,
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            // Danh sách dữ liệu chờ
            if (_syncService.getPendingDataCount() > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Dữ liệu chờ đẩy:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('Collection')),
                    DataColumn(label: Text('Doc ID')),
                  ],
                  rows: _syncService.getPendingData().map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['collection'] as String)),
                        DataCell(
                          Text(
                            (item['docId'] as String).substring(0, 8) + '...',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleAutoSync() {
    setState(() {
      if (_syncService.isAutoSyncEnabled()) {
        _syncService.stopAutoSync();
      } else {
        _syncService.startAutoSync(
          intervalSeconds: _syncService.getSyncInterval(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _syncService.isAutoSyncEnabled() ? 'Auto Sync bật' : 'Auto Sync tắt',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _syncNow() async {
    await _syncService.syncNow();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sync!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearPending() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu chờ?'),
        content: const Text('Bạn chắc chắn muốn xóa tất cả dữ liệu chờ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _syncService.clearPendingData();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _updateInterval() {
    try {
      int seconds = int.parse(_intervalController.text);
      if (seconds < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tối thiểu 5 giây')),
        );
        return;
      }

      _syncService.setSyncInterval(seconds);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt interval: $seconds giây')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số hợp lệ')),
      );
    }
  }
}

/// Dialog để tạo article
Future<void> showCreateArticleDialog(BuildContext context) async {
  final syncService = FirebaseSyncService();
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final categoryController = TextEditingController();
  bool autoUpload = true;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Tạo Article Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Nội dung'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Tải lên ngay'),
                value: autoUpload,
                onChanged: (value) {
                  setState(() {
                    autoUpload = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nhập tiêu đề')),
                );
                return;
              }

              try {
                await syncService.createArticle(
                  title: titleController.text,
                  content: contentController.text,
                  category: categoryController.text,
                  autoUpload: autoUpload,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Article created!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    ),
  );
}
