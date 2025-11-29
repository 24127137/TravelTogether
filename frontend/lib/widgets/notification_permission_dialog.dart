import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Dialog xin quyền thông báo từ người dùng
/// Hiển thị lần đầu tiên khi vào app
class NotificationPermissionDialog {
  /// Hiển thị dialog xin quyền
  /// Trả về true nếu user cấp quyền
  static Future<bool> show(BuildContext context) async {
    // Kiểm tra đã có quyền chưa
    final hasPermission = await NotificationService().checkPermission();
    if (hasPermission) {
      debugPrint('✅ Notification permission already granted');
      return true;
    }

    // Hiển thị dialog giải thích tại sao cần quyền
    final shouldAsk = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User phải chọn
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEDE2CC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB99668),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cho phép thông báo',
                  style: TextStyle(
                    color: Color(0xFFA15C20),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Travel Together muốn gửi thông báo đến bạn để:',
                style: TextStyle(
                  color: Color(0xFF1B1E28),
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.message,
                'Nhận tin nhắn mới từ nhóm',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.group_add,
                'Thông báo yêu cầu tham gia nhóm',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.schedule,
                'Nhắc nhở về kế hoạch du lịch',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.smart_toy,
                'Phản hồi từ AI Travel Assistant',
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có thể thay đổi cài đặt này bất cứ lúc nào trong phần Cài đặt.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Không',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB99668),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cho phép',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldAsk == true) {
      // User đồng ý, xin quyền từ hệ thống
      final granted = await NotificationService().requestPermission();

      if (!context.mounted) return granted;

      if (granted) {
        // Hiển thị thông báo test
        await _showTestNotification(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã bật thông báo thành công!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể bật thông báo. Vui lòng kiểm tra cài đặt hệ thống.'),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return granted;
    }

    return false;
  }

  /// Helper widget để hiển thị tính năng
  static Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFB99668),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1B1E28),
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Gửi notification test sau khi cấp quyền
  static Future<void> _showTestNotification(BuildContext context) async {
    await NotificationService().showNotification(
      id: 999,
      title: '🎉 Thành công!',
      body: 'Bạn sẽ nhận được thông báo từ Travel Together',
      payload: 'test',
      priority: NotificationPriority.normal,
    );
  }
}

