// list_group_feedback.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/feedback_models.dart';
import '../../services/feedback_service.dart';
import '../../services/auth_service.dart';
import 'feedback_screen.dart';
// import 'login_screen.dart'; // Import màn hình login nếu cần chuyển hướng

class ListGroupFeedbackScreen extends StatefulWidget {
  const ListGroupFeedbackScreen({super.key});

  @override
  State<ListGroupFeedbackScreen> createState() => _ListGroupFeedbackScreenState();
}

class _ListGroupFeedbackScreenState extends State<ListGroupFeedbackScreen> {
  final FeedbackService _service = FeedbackService();

  Future<List<PendingReviewGroup>>? _pendingGroupsFuture;
  String? _accessToken;
  bool _isCheckingToken = true; // Biến để hiện loading lúc đang check token

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Hàm khởi tạo dữ liệu: Lấy Token -> Gọi API
  Future<void> _initData() async {
    // 1. Lấy token hợp lệ từ AuthService (Nó đã tự xử lý refresh token nếu cần)
    final token = await AuthService.getValidAccessToken();

    if (token != null && token.isNotEmpty) {
      if (mounted) {
        setState(() {
          _accessToken = token;
          _isCheckingToken = false;
          // 2. Có token rồi thì mới gọi API lấy danh sách
          _pendingGroupsFuture = _service.getPendingReviews(token);
        });
      }
    } else {
      // 3. Nếu không lấy được token (Hết hạn quá lâu hoặc chưa login)
      if (mounted) {
        setState(() {
          _isCheckingToken = false;
        });
        _showLoginRequiredDialog();
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Yêu cầu đăng nhập".tr()),
        content: Text("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.".tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(context); // Quay lại màn hình trước
              // Hoặc: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: Text("OK".tr()),
          )
        ],
      ),
    );
  }

  void _refreshData() {
    // Gọi lại quy trình lấy token để đảm bảo token vẫn còn hạn
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("GÓP Ý".tr(), style: const TextStyle(color: Colors.white, fontFamily: 'Alumni Sans', fontSize: 28, fontWeight: FontWeight.bold)),
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
              ),
            ),
          ),

          // 2. Nội dung list
          SafeArea(
            child: _isCheckingToken
                ? const Center(child: CircularProgressIndicator(color: Colors.white)) // Đang check token
                : _accessToken == null
                ? Center(child: Text("Vui lòng đăng nhập".tr(), style: const TextStyle(color: Colors.white)))
                : FutureBuilder<List<PendingReviewGroup>>(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Lỗi tải dữ liệu: ${snapshot.error}'.tr(), style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _refreshData, child: Text('Thử lại'.tr(), style: const TextStyle(color: Colors.orangeAccent))),
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
          if (_accessToken == null) return;

          // Chuyển sang màn hình FeedbackScreen với token thật
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                groupData: group,
                accessToken: _accessToken!, // Truyền token thật vào đây
              ),
            ),
          );

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
                  : const AssetImage('assets/images/default_group.jpg'),
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