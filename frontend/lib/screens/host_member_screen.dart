import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../widgets/out_group_dialog.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/chat_system_message_service.dart';
import 'main_app_screen.dart';
import '../services/feedback_service.dart';
import '../models/feedback_models.dart';


class MemberScreenHost extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int currentMembers;
  final int maxMembers;
  final List<Member> members;
  final bool openPendingTab;

  const MemberScreenHost({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentMembers,
    required this.maxMembers,
    required this.members,
    this.openPendingTab = false,
  });

  @override
  State<MemberScreenHost> createState() => _MemberScreenHostState();
}

// === SỬA ĐỔI: Thêm WidgetsBindingObserver để handle app lifecycle ===
class _MemberScreenHostState extends State<MemberScreenHost> with WidgetsBindingObserver {
  bool _showMembers = true;
  bool _isApproving = false;
  bool _isRejecting = false;
  String _searchQuery = '';
  final Set<String> _selectedRequests = <String>{};
  final FeedbackService _feedbackService = FeedbackService();
  late List<Member> _filteredMembers;
  List<PendingRequest> _pendingRequests = [];
  List<PendingRequest> _filteredRequests = [];
  bool _isLoadingRequests = false;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    // === THÊM: Register observer ===
    WidgetsBinding.instance.addObserver(this);

    _showMembers = !widget.openPendingTab;
    _updateFilteredLists();
    _loadAccessToken();
  }

  @override
  void dispose() {
    // === THÊM: Unregister observer ===
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // === SỬA ĐỔI: Handle app lifecycle với đúng signature ===
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _loadAccessToken() async {
    // === SỬA ĐỔI: Loại bỏ SharedPreferences duplicate ===
    _accessToken = await AuthService.getValidAccessToken();

    if (_accessToken != null) {
      await _fetchPendingRequests();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_login_token'.tr())),
        );
      }
    }
  }

  Future<void> _fetchPendingRequests() async {
    if (_accessToken == null) return;

    setState(() {
      _isLoadingRequests = true;
    });

    try {
      // === SỬA: Refresh token trước mỗi API call ===
      _accessToken = await AuthService.getValidAccessToken();

      final url = Uri.parse('${ApiConfig.baseUrl}/groups/${widget.groupId}/requests');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        _pendingRequests = data.map((item) => PendingRequest(
          id: item['profile_uuid'] as String,
          name: item['fullname'] as String,
          email: item['email'] as String,
          avatarUrl: item['avatar_url'] as String?,
          requestedAt: DateTime.parse(item['requested_at'] as String),
          rating: 0.0,
          topTags: [],
        )).toList();

        setState(() {
          _updateFilteredLists();
        });

        // Fetch reputation cho từng pending user
        await _fetchReputationsForPendingUsers();

        setState(() {
          _isLoadingRequests = false;
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
          );
        }
        setState(() {
          _isLoadingRequests = false;
        });
      } else {
        setState(() {
          _isLoadingRequests = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải danh sách: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  Future<void> _fetchReputationsForPendingUsers() async {
    if (_accessToken == null || _pendingRequests.isEmpty) return;

    // Tạo list các Future để gọi song song
    List<Future<void>> futures = [];

    for (int i = 0; i < _pendingRequests.length; i++) {
      futures.add(_fetchSingleUserReputation(i));
    }

    // Gọi tất cả song song
    await Future.wait(futures);
  }

  // Thay thế hàm _fetchSingleUserReputation cũ bằng hàm này
  Future<void> _fetchSingleUserReputation(int index) async {
    // Kiểm tra index hợp lệ để tránh lỗi RangeError
    if (index >= _pendingRequests.length) return;

    final request = _pendingRequests[index];

    try {
      print('🔍 Đang lấy reputation cho: ${request.name} (${request.id})');
      final reputationData = await _feedbackService.getUserReputation(_accessToken!, request.id);

      if (reputationData != null && mounted) {
        print('✅ Đã lấy được reputation: ${reputationData.averageRating} sao, ${reputationData.groups.length} nhóm');

        // Tính top 3 tags từ tất cả feedbacks
        Map<String, int> tagCount = {};

        for (var group in reputationData.groups) {
          for (var feedback in group.feedbacks) {
            for (var tag in feedback.content) {
              tagCount[tag] = (tagCount[tag] ?? 0) + 1;
            }
          }
        }

        // Sắp xếp và lấy top 3
        List<MapEntry<String, int>> sortedTags = tagCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        List<String> top3Tags = sortedTags.take(3).map((e) => e.key).toList();

        setState(() {
          // Kiểm tra lại index một lần nữa trước khi update
          if (index < _pendingRequests.length) {
            _pendingRequests[index] = PendingRequest(
              id: request.id,
              name: request.name,
              email: request.email,
              avatarUrl: request.avatarUrl,
              requestedAt: request.requestedAt,
              rating: reputationData.averageRating, // Update rating
              topTags: top3Tags, // Update tags
            );
            _updateFilteredLists();
          }
        });
      } else {
        print('⚠️ Reputation data trả về NULL cho user: ${request.name}');
      }
    } catch (e) {
      print('❌ Lỗi khi lấy reputation cho ${request.id}: $e');
    }
  }

  // === SỬA ĐỔI: Hoàn thiện implementation của _approveSelectedRequests ===
  Future<void> _approveSelectedRequests() async {
    if (_selectedRequests.isEmpty || _isApproving) return;

    setState(() {
      _isApproving = true;
    });

    try {
      final totalAfterAccept = currentMemberCount + _selectedRequests.length;

      // Kiểm tra giới hạn thành viên
      if (totalAfterAccept > widget.maxMembers) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Không thể phê duyệt! Nhóm chỉ còn ${widget.maxMembers - currentMemberCount} chỗ trống. '
                      'Bạn đang chọn ${_selectedRequests.length} yêu cầu.'
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      _accessToken = await AuthService.getValidAccessToken();
      if (_accessToken == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang xử lý...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      int successCount = 0;
      int failCount = 0;
      List<PendingRequest> approvedRequests = [];

      // Xử lý từng request
      for (String profileUuid in _selectedRequests) {
        // Kiểm tra giới hạn trong quá trình approve
        if (currentMemberCount + successCount >= widget.maxMembers) {
          failCount += (_selectedRequests.length - successCount - failCount);
          break;
        }

        final success = await _performMemberAction(profileUuid, 'accept');
        if (success) {
          successCount++;
          // Tìm request được approve để thêm vào danh sách members
          final approvedRequest = _pendingRequests.firstWhere(
                (request) => request.id == profileUuid,
          );
          approvedRequests.add(approvedRequest);
        } else {
          failCount++;
        }
      }

      // Cập nhật UI sau khi hoàn thành
      if (successCount > 0) {
        // === THÊM MỚI: Gửi system message cho mỗi thành viên mới ===
        for (var request in approvedRequests) {
          await ChatSystemMessageService.sendJoinGroupMessage(
            groupId: widget.groupId,
            memberName: request.name,
          );
        }

        setState(() {
          // Thêm các thành viên mới được approve vào danh sách members
          for (var request in approvedRequests) {
            widget.members.add(Member(
              id: request.id,
              name: request.name,
              email: request.email,
              avatarUrl: request.avatarUrl,
            ));
          }

          // Xóa các requests đã được approve khỏi pending list
          _pendingRequests.removeWhere(
                (request) => approvedRequests.any((approved) => approved.id == request.id),
          );

          _selectedRequests.clear();
          _updateFilteredLists();
        });
      }

      // Hiển thị kết quả
      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã phê duyệt $successCount yêu cầu thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          String message = 'Thành công: $successCount, Thất bại: $failCount';
          if (currentMemberCount >= widget.maxMembers) {
            message += '\nNhóm đã đầy!';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // === QUAN TRỌNG: Luôn reset loading state ===
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }

  // === Các methods còn lại giữ nguyên ===
  void _updateFilteredLists() {
    _filteredMembers = widget.members
        .where((member) =>
    member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        member.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    _filteredRequests = _pendingRequests
        .where((request) =>
    request.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        request.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _updateFilteredLists();
    });
  }

  void _toggleSelection(String requestId) {
    setState(() {
      if (_selectedRequests.contains(requestId)) {
        _selectedRequests.remove(requestId);
      } else {
        _selectedRequests.add(requestId);
      }
    });
  }

  Future<bool> _performMemberAction(String profileUuid, String action) async {
    _accessToken = await AuthService.getValidAccessToken();
    if (_accessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xác thực. Vui lòng đăng nhập lại.')),
        );
      }
      return false;
    }

    try {
      final url = ApiConfig.getUri(ApiConfig.groupManage);

      final requestBody = {
        "group_id": widget.groupId,
        "profile_uuid": profileUuid,
        "action": action,
      };

      print('📤 PATCH ${ApiConfig.groupManage}');
      print('📤 Request body: ${json.encode(requestBody)}');

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
          );
        }
        return false;
      } else if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn không có quyền thực hiện hành động này')),
          );
        }
        return false;
      } else {
        print('❌ Action $action failed for $profileUuid: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi ${response.statusCode}: ${response.body}')),
          );
        }
        return false;
      }
    } catch (e) {
      print('❌ Error performing action $action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _refreshData() async {
    await _fetchPendingRequests();
  }

  // === Các methods còn lại giữ nguyên ===
  Future<void> _rejectRequest(String requestId) async {
    _accessToken = await AuthService.getValidAccessToken();

    final success = await _performMemberAction(requestId, 'reject');

    if (success) {
      setState(() {
        _pendingRequests.removeWhere((request) => request.id == requestId);
        _selectedRequests.remove(requestId);
        _updateFilteredLists();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối yêu cầu')),
        );
      }
    }
  }

  Future<void> _kickMember(Member member) async {
    _accessToken = await AuthService.getValidAccessToken();

    // === THÊM MỚI: Gửi system message TRƯỚC khi kick ===
    await ChatSystemMessageService.sendKickMemberMessage(
      groupId: widget.groupId,
      memberName: member.name,
    );

    final success = await _performMemberAction(member.id, 'kick');

    if (success) {
      setState(() {
        widget.members.remove(member);
        _updateFilteredLists();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã kick ${member.name} khỏi nhóm')),
        );
      }
    }
  }

  int get currentMemberCount => widget.members.length;

  // === Widget builds giữ nguyên từ code gốc ===
  Widget _buildAvatar(String? avatarUrl, {double radius = 30}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD9CBB3),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: const Color(0xFFB99668),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: radius,
                color: Colors.white,
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD9CBB3),
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/members.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildMemberCount(),
              _buildTabButtons(),
              _buildSearchBar(),
              Expanded(
                child: _showMembers ? _buildMembersList() : _buildPendingList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget để hiển thị avatar với error handling

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: const ShapeDecoration(
                color: Color(0xFFF6F6F8),
                shape: CircleBorder(),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontFamily: 'Alumni Sans',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: (_isApproving || _isRejecting) ? null : () {
              if (_showMembers) {
                OutGroupDialog.show(
                  context,
                  groupId: widget.groupId,
                  isHost: true,
                  onSuccess: () async {
                    // Lấy accessToken để navigate về MainAppScreen
                    final accessToken = await AuthService.getValidAccessToken() ?? '';

                    // Navigate về MessagesScreen (index 2) và refresh
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => MainAppScreen(
                            initialIndex: 2,
                            accessToken: accessToken,
                          ),
                        ),
                        (route) => false, // Remove tất cả routes cũ
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã giải tán nhóm thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                );
              } else {
                if (_selectedRequests.isNotEmpty) {
                  _approveSelectedRequests();
                }
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: ShapeDecoration(
                color: _showMembers
                    ? const Color(0xFFF6F6F8)
                    : (_selectedRequests.isNotEmpty && !_isApproving
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF6F6F8)),
                shape: const CircleBorder(),
              ),
              child: _isApproving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                _showMembers ? Icons.exit_to_app : Icons.check,
                size: 20,
                color: _showMembers
                    ? Colors.black
                    : (_selectedRequests.isNotEmpty ? Colors.white : Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Center(
        child: Text(
          '$currentMemberCount / ${widget.maxMembers}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'Alegreya',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButtons() {
    bool hasPending = _pendingRequests.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          // Nút Thành viên
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMembers = true),
              child: Container(
                height: 54,
                decoration: ShapeDecoration(
                  color: _showMembers ? const Color(0xFFDCC9A7) : Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFB99668)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Center(
                  child: Text(
                    'members'.tr(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Alumni Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Nút Chờ xác nhận (CÓ CHẤM CAM)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMembers = false),
              child: Stack( // Dùng Stack để đè chấm cam lên
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 54,
                    decoration: ShapeDecoration(
                      color: !_showMembers ? const Color(0xFFDCC9A7) : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFB99668)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Chờ xác nhận',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Alumni Sans',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  // DOT MÀU CAM
                  if (hasPending)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.redAccent, // Hoặc màu cam: Colors.orange
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        height: 50,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFB99668)),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: TextField(
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: Color(0xFFB99668)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            hintText: 'Tìm kiếm...',
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        return Dismissible(
          key: Key(member.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Xác nhận'),
                  content: Text('Bạn có chắc muốn kick ${member.name} khỏi nhóm?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Kick'),
                    ),
                  ],
                );
              },
            );

            if (confirmed == true) {
              await _kickMember(member);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildMemberCard(member),
        );
      },
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      height: 120,
      decoration: ShapeDecoration(
        color: const Color(0xFFB99668),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(member.avatarUrl, radius: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 18,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_isLoadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB99668)),
      );
    }

    if (_filteredRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFB99668),
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'Không có yêu cầu nào\nKéo để làm mới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFB99668),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final request = _filteredRequests[index];
          return Dismissible(
            key: Key(request.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              await _rejectRequest(request.id);
              return true;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: _buildPendingCard(request),
          );
        },
      ),
    );
  }

  Widget _buildPendingCard(PendingRequest request) {
    final isSelected = _selectedRequests.contains(request.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE7DA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB29079),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(request.avatarUrl, radius: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 18,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  request.email,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 6),

                // Rating row
                if (request.rating > 0)
                  Row(
                    children: [
                      Text(
                        request.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(request.requestedAt),
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 11,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _formatDateTime(request.requestedAt),
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                      fontFamily: 'DM Sans',
                    ),
                  ),

                const SizedBox(height: 8),

                // Top 3 Tags
                if (request.topTags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: request.topTags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6D9BE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag.tr(),
                        style: const TextStyle(
                          color: Color(0xFF4A3728),
                          fontSize: 11,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  )
                else
                  Text(
                    'Chưa có đánh giá',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _toggleSelection(request.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: ShapeDecoration(
                color: isSelected ? const Color(0xFFE6D9BE) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFE6D9BE) : const Color(0xFF666666),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF222222), size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Data models
class Member {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  Member({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

class PendingRequest {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime requestedAt;
  final double rating;
  final List<String> topTags;

  PendingRequest({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.requestedAt,
    this.rating = 0.0,
    this.topTags = const [],
  });
}