import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/feedback_models.dart';
import '../../services/feedback_service.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart'; // <--- Import GroupService
import 'feedback_screen.dart';

class ListGroupFeedbackScreen extends StatefulWidget {
  const ListGroupFeedbackScreen({super.key});

  @override
  State<ListGroupFeedbackScreen> createState() => _ListGroupFeedbackScreenState();
}

class _ListGroupFeedbackScreenState extends State<ListGroupFeedbackScreen> {
  final FeedbackService _service = FeedbackService();
  Future<List<PendingReviewGroup>>? _pendingGroupsFuture;
  String? _accessToken;
  bool _isCheckingToken = true;

  @override
  void initState() {
    super.initState();
    _loadDataWithAuth();
  }

  Future<void> _loadDataWithAuth() async {
    String? token = await AuthService.getValidAccessToken();
    if (mounted) {
      if (token != null && token.isNotEmpty) {
        setState(() {
          _accessToken = token;
          _isCheckingToken = false;
          _pendingGroupsFuture = _service.getPendingReviews(token);
        });
      } else {
        setState(() => _isCheckingToken = false);
        _showLoginRequired();
      }
    }
  }

  void _showLoginRequired() { /* ... Giữ nguyên ... */ }

  void _refreshData() { _loadDataWithAuth(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Nhận xét".tr(), style: const TextStyle(color: Colors.white, fontFamily: 'Alumni Sans', fontSize: 28, fontWeight: FontWeight.bold)),
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/list_group.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: _isCheckingToken
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _accessToken == null
                ? Center(child: Text("Vui lòng đăng nhập".tr(), style: const TextStyle(color: Colors.white)))
                : FutureBuilder<List<PendingReviewGroup>>(
              future: _pendingGroupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Bạn đã đánh giá hết các chuyến đi!'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18)));
                }

                final groups = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    // Dùng Widget mới để tự load ảnh
                    return _PendingGroupCard(
                      group: group,
                      accessToken: _accessToken!,
                      onFeedbackComplete: _refreshData,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET MỚI: TỰ ĐỘNG LOAD ẢNH NẾU THIẾU ===
class _PendingGroupCard extends StatefulWidget {
  final PendingReviewGroup group;
  final String accessToken;
  final VoidCallback onFeedbackComplete;

  const _PendingGroupCard({
    required this.group,
    required this.accessToken,
    required this.onFeedbackComplete,
  });

  @override
  State<_PendingGroupCard> createState() => _PendingGroupCardState();
}

class _PendingGroupCardState extends State<_PendingGroupCard> {
  final GroupService _groupService = GroupService();
  String? _fetchedImageUrl; // Ảnh lấy từ API public-plan

  @override
  void initState() {
    super.initState();
    // Nếu model chưa có ảnh, gọi API lấy bù
    if (widget.group.groupImageUrl == null || widget.group.groupImageUrl!.isEmpty) {
      _fetchGroupImage();
    }
  }

  Future<void> _fetchGroupImage() async {
    try {
      final data = await _groupService.getGroupPlanById(widget.accessToken, widget.group.groupId);
      if (data != null && data['group_image_url'] != null) {
        if (mounted) {
          setState(() {
            _fetchedImageUrl = data['group_image_url'];
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên ảnh lấy được, sau đó đến ảnh có sẵn, cuối cùng là mặc định
    String? displayImage = _fetchedImageUrl ?? widget.group.groupImageUrl;
    bool hasImage = displayImage != null && displayImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE7DA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB29079),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                groupData: widget.group,
                accessToken: widget.accessToken,
              ),
            ),
          );
          if (result == true) widget.onFeedbackComplete();
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: hasImage
                  ? NetworkImage(displayImage!) as ImageProvider
                  : const AssetImage('assets/images/default_group.jpg'),
              fit: BoxFit.cover,
              onError: (_, __) {},
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
                  widget.group.groupName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Alumni Sans'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.group.unreviewedMembers.length} thành viên cần đánh giá'.tr(),
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