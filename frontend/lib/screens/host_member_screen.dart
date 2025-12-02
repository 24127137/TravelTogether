import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/out_group_dialog.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class MemberScreenHost extends StatefulWidget {
  final String groupName;
  final int currentMembers;
  final int maxMembers;
  final List<Member> members;
  final bool openPendingTab;

  const MemberScreenHost({
    super.key,
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
          const SnackBar(content: Text('Không tìm thấy token đăng nhập')),
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

      final url = ApiConfig.getUri(ApiConfig.groupManageRequests);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_accessToken",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _pendingRequests = data.map((item) => PendingRequest(
            id: item['profile_uuid'] as String,
            name: item['fullname'] as String,
            email: item['email'] as String,
            avatarUrl: item['avatar_url'] as String?,
            requestedAt: DateTime.parse(item['requested_at'] as String),
            rating: 4.5,
            keywords: [],
          )).toList();

          _updateFilteredLists();
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
                  isHost: true,
                  onSuccess: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã giải tán nhóm thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
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
                child: const Center(
                  child: Text(
                    'Thành viên',
                    style: TextStyle(
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
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMembers = false),
              child: Container(
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
      height: 135,
      decoration: ShapeDecoration(
        color: const Color(0xFFB99668),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(request.avatarUrl, radius: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
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
                Text(
                  'Yêu cầu lúc: ${_formatDateTime(request.requestedAt)}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
  final List<String> keywords;

  PendingRequest({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.requestedAt,
    this.rating = 0.0,
    this.keywords = const [],
  });
}