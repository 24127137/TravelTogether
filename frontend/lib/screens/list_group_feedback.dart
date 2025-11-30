<<<<<<< HEAD
=======
// list_group_feedback.dart
>>>>>>> 3ee7efe (done all groupapis)
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/feedback_models.dart';
import '../../services/feedback_service.dart';
import '../../services/auth_service.dart';
<<<<<<< HEAD
import '../../services/group_service.dart'; // <--- Import GroupService
import 'feedback_screen.dart';
=======
import 'feedback_screen.dart';
// import 'login_screen.dart'; // Import màn hình login nếu cần chuyển hướng
>>>>>>> 3ee7efe (done all groupapis)

class ListGroupFeedbackScreen extends StatefulWidget {
  const ListGroupFeedbackScreen({super.key});

  @override
  State<ListGroupFeedbackScreen> createState() => _ListGroupFeedbackScreenState();
}

class _ListGroupFeedbackScreenState extends State<ListGroupFeedbackScreen> {
  final FeedbackService _service = FeedbackService();
<<<<<<< HEAD
  Future<List<PendingReviewGroup>>? _pendingGroupsFuture;
  String? _accessToken;
  bool _isCheckingToken = true;
=======

  Future<List<PendingReviewGroup>>? _pendingGroupsFuture;
  String? _accessToken;
  bool _isCheckingToken = true; // Biến để hiện loading lúc đang check token
>>>>>>> 3ee7efe (done all groupapis)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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
=======
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
>>>>>>> 3ee7efe (done all groupapis)
      }
    }
  }

<<<<<<< HEAD
  void _showLoginRequired() { /* ... Giữ nguyên ... */ }

  void _refreshData() { _loadDataWithAuth(); }
=======
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
>>>>>>> 3ee7efe (done all groupapis)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
<<<<<<< HEAD
        title: Text("Nhận xét".tr(), style: const TextStyle(color: Colors.white, fontFamily: 'Alumni Sans', fontSize: 28, fontWeight: FontWeight.bold)),
=======
        title: Text("Đánh giá chuyến đi".tr(), style: const TextStyle(color: Colors.white, fontFamily: 'Alumni Sans', fontSize: 28, fontWeight: FontWeight.bold)),
>>>>>>> 3ee7efe (done all groupapis)
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
<<<<<<< HEAD
=======
          // 1. Ảnh nền local
>>>>>>> 3ee7efe (done all groupapis)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/list_group.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
<<<<<<< HEAD
          SafeArea(
            child: _isCheckingToken
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
=======

          // 2. Nội dung list
          SafeArea(
            child: _isCheckingToken
                ? const Center(child: CircularProgressIndicator(color: Colors.white)) // Đang check token
>>>>>>> 3ee7efe (done all groupapis)
                : _accessToken == null
                ? Center(child: Text("Vui lòng đăng nhập".tr(), style: const TextStyle(color: Colors.white)))
                : FutureBuilder<List<PendingReviewGroup>>(
              future: _pendingGroupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
<<<<<<< HEAD
                  return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Bạn đã đánh giá hết các chuyến đi!'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18)));
                }

                final groups = snapshot.data!;
=======
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

>>>>>>> 3ee7efe (done all groupapis)
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
<<<<<<< HEAD
                    // Dùng Widget mới để tự load ảnh
                    return _PendingGroupCard(
                      group: group,
                      accessToken: _accessToken!,
                      onFeedbackComplete: _refreshData,
                    );
=======
                    return _buildGroupCard(group);
>>>>>>> 3ee7efe (done all groupapis)
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
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

=======

  Widget _buildGroupCard(PendingReviewGroup group) {
>>>>>>> 3ee7efe (done all groupapis)
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
<<<<<<< HEAD
=======
          if (_accessToken == null) return;

          // Chuyển sang màn hình FeedbackScreen với token thật
>>>>>>> 3ee7efe (done all groupapis)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
<<<<<<< HEAD
                groupData: widget.group,
                accessToken: widget.accessToken,
              ),
            ),
          );
          if (result == true) widget.onFeedbackComplete();
=======
                groupData: group,
                accessToken: _accessToken!, // Truyền token thật vào đây
              ),
            ),
          );

          if (result == true) {
            _refreshData();
          }
>>>>>>> 3ee7efe (done all groupapis)
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            image: DecorationImage(
<<<<<<< HEAD
              image: hasImage
                  ? NetworkImage(displayImage!) as ImageProvider
                  : const AssetImage('assets/images/default_group.jpg'),
              fit: BoxFit.cover,
              onError: (_, __) {},
=======
              image: (group.groupImageUrl != null && group.groupImageUrl!.isNotEmpty)
                  ? NetworkImage(group.groupImageUrl!) as ImageProvider
                  : const AssetImage('assets/images/default_group.jpg'),
              fit: BoxFit.cover,
>>>>>>> 3ee7efe (done all groupapis)
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
<<<<<<< HEAD
                  widget.group.groupName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Alumni Sans'),
=======
                  group.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alumni Sans',
                  ),
>>>>>>> 3ee7efe (done all groupapis)
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
<<<<<<< HEAD
                      '${widget.group.unreviewedMembers.length} thành viên cần đánh giá'.tr(),
=======
                      '${group.unreviewedMembers.length} thành viên cần đánh giá'.tr(),
>>>>>>> 3ee7efe (done all groupapis)
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