// list_group_feedback.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/feedback_models.dart';
import '../../services/feedback_service.dart';
import 'feedback_screen.dart';

class ListGroupFeedbackScreen extends StatefulWidget {
  const ListGroupFeedbackScreen({super.key});

  @override
  State<ListGroupFeedbackScreen> createState() => _ListGroupFeedbackScreenState();
}

class _ListGroupFeedbackScreenState extends State<ListGroupFeedbackScreen> {
  // Giả lập token, thực tế bạn lấy từ AuthProvider/Storage
  final String _fakeToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6IjQ4Ukk2RTJWbEpFQkJMN3ciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL21ldXFudHZhd2FrZHpudGV3c2NwLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiJiYWZiYWQ1MS0xYzg3LTQ1MDYtOWJmMC1kYzgyZGU4ZTAzNjUiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzY0NDQ4OTA2LCJpYXQiOjE3NjQwODg5MDYsImVtYWlsIjoia2hvYUB0ZXN0LmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWwiOiJraG9hQHRlc3QuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBob25lX3ZlcmlmaWVkIjpmYWxzZSwic3ViIjoiYmFmYmFkNTEtMWM4Ny00NTA2LTliZjAtZGM4MmRlOGUwMzY1In0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NjQwODg5MDZ9XSwic2Vzc2lvbl9pZCI6IjhjYmVmZDcwLWRiZmMtNGU4OC05ZWRhLTY2OWFmYmFhOWY1YyIsImlzX2Fub255bW91cyI6ZmFsc2V9.SVZ8bJ3CxKQxD7xDlMSAO9xJeewEY81-3ZB2zcDnOd0";
  final FeedbackService _service = FeedbackService();

  late Future<List<PendingReviewGroup>> _pendingGroupsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _pendingGroupsFuture = _service.getPendingReviews(_fakeToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Background image setup
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Đánh giá chuyến đi".tr(), style: const TextStyle(color: Colors.white, fontFamily: 'Alumni Sans', fontSize: 28, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Ảnh nền local
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/list_group.png'),
                fit: BoxFit.cover,
                // colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken), // Làm tối ảnh nền chút
              ),
            ),
          ),

          // 2. Nội dung list
          SafeArea(
            child: FutureBuilder<List<PendingReviewGroup>>(
              future: _pendingGroupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text('Lỗi tải dữ liệu'.tr(), style: const TextStyle(color: Colors.white)),
                        TextButton(onPressed: _refreshData, child: Text('Thử lại'.tr())),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Bạn đã đánh giá hết các chuyến đi!'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                final groups = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildGroupCard(group);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(PendingReviewGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Navigate tới màn FeedbackScreen với dữ liệu nhóm
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                groupData: group, // Truyền data nhóm vào
              ),
            ),
          );

          // Khi quay lại, refresh list vì có thể user đã đánh giá xong nhóm đó
          if (result == true) {
            _refreshData();
          }
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: (group.groupImageUrl != null && group.groupImageUrl!.isNotEmpty)
                  ? NetworkImage(group.groupImageUrl!) as ImageProvider
                  : const AssetImage('assets/images/default_group.jpg'), // Ảnh mặc định
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alumni Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${group.unreviewedMembers.length} thành viên cần đánh giá'.tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}