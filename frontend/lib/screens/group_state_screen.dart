import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class GroupStateScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const GroupStateScreen({
    Key? key,
    this.onBack,
  }) : super(key: key);

  @override
  State<GroupStateScreen> createState() => _GroupStateScreenState();
}

class _GroupStateScreenState extends State<GroupStateScreen> {
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();

  List<GroupApplication> _applications = [];
  List<GroupApplication> _filteredApplications = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) return;

    try {
      final profile = await _userService.getUserProfile();
      if (profile != null) {
        List requests = profile['pending_requests'] ?? [];

        // Chuyển đổi dữ liệu JSON sang Model
        List<GroupApplication> loadedApps = [];

        for (var req in requests) {
          // Chỉ lấy những yêu cầu đang PENDING
          // (Thực ra trong DB thường chỉ lưu pending, nhưng check cho chắc)
          if (req['status'] == 'pending') {
            loadedApps.add(GroupApplication(
              id: req['group_id'].toString(), // ID nhóm
              groupName: req['group_name'] ?? 'Nhóm chưa đặt tên',
              status: ApplicationStatus.pending,
              // Avatar tạm thời để null, sẽ load sau
              avatar: null,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _applications = loadedApps;
            _filteredApplications = List.from(loadedApps);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi load pending requests: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteApplication(String groupIdStr) async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) return;

    int groupId = int.parse(groupIdStr);

    // Gọi API hủy
    bool success = await _groupService.cancelJoinRequest(token, groupId);

    if (success) {
      setState(() {
        _applications.removeWhere((app) => app.id == groupIdStr);
        _filteredApplications.removeWhere((app) => app.id == groupIdStr);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy yêu cầu'.tr()), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi hủy yêu cầu'.tr()), backgroundColor: Colors.red),
      );
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredApplications = List.from(_applications);
      } else {
        _filteredApplications = _applications
            .where((app) => app.groupName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/state_background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) widget.onBack!();
                        else Navigator.pop(context);
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: Color(0xFFF6F6F8), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'group_list'.tr(),
                  style: const TextStyle(fontSize: 60, fontFamily: 'Alumni Sans', fontWeight: FontWeight.w800, color: Color(0xFFB99668)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Text(
                  'pending_groups'.tr(), // "Các nhóm đang chờ duyệt"
                  style: const TextStyle(fontSize: 32, fontFamily: 'Alegreya', fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 0),
                child: Container(
                  height: 63,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE2CC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFCD7F32), width: 2),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search, color: Color(0xFF8A724C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'search_group'.tr(),
                            border: InputBorder.none,
                            hintStyle: const TextStyle(color: Color(0xFF8A724C)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 130),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB99668)))
                        : _filteredApplications.isEmpty
                        ? Center(child: Text('no_requests'.tr(), style: TextStyle(fontSize: 16, color: Colors.grey[600])))
                        : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredApplications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Dùng Widget Stateful để tự load ảnh
                        return ApplicationCard(
                          application: _filteredApplications[index],
                          onDelete: () => _deleteApplication(_filteredApplications[index].id),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// === CARD HIỂN THỊ (Stateful để Load Ảnh) ===
class ApplicationCard extends StatefulWidget {
  final GroupApplication application;
  final VoidCallback onDelete;

  const ApplicationCard({
    Key? key,
    required this.application,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<ApplicationCard> {
  final GroupService _groupService = GroupService();
  String? _fetchedImage;

  @override
  void initState() {
    super.initState();
    if (widget.application.avatar == null) {
      _loadGroupImage();
    }
  }

  Future<void> _loadGroupImage() async {
    String? token = await AuthService.getValidAccessToken();
    if (token != null) {
      try {
        int groupId = int.parse(widget.application.id);
        final data = await _groupService.getGroupPlanById(token, groupId);
        if (data != null && data['group_image_url'] != null && mounted) {
          setState(() {
            _fetchedImage = data['group_image_url'];
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _fetchedImage ?? widget.application.avatar;
    final hasImage = displayImage != null && displayImage.isNotEmpty;

    return Dismissible(
      key: Key(widget.application.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('confirm_delete'.tr()), // "Xác nhận hủy?"
              content: Text('delete_request_message'.tr()), // "Bạn có chắc muốn hủy yêu cầu này?"
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr())),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('delete'.tr(), style: const TextStyle(color: Colors.red))),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => widget.onDelete(),
      background: Container(
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB99668),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: hasImage
                      ? NetworkImage(displayImage!) as ImageProvider
                      : const AssetImage('assets/images/default_group.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Group name
            Expanded(
              child: Text(
                widget.application.groupName,
                style: const TextStyle(color: Color(0xFF222222), fontSize: 18, fontFamily: 'DM Sans', fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            // Status badge (Luôn là Pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFCD7F32), borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('status_pending'.tr(), style: const TextStyle(color: Colors.black, fontSize: 10, fontFamily: 'DM Sans', fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
enum ApplicationStatus { pending, accepted, rejected }

class GroupApplication {
  final String id;
  final String groupName;
  final String? avatar; // Cho phép null
  final ApplicationStatus status;

  GroupApplication({
    required this.id,
    required this.groupName,
    this.avatar,
    required this.status,
  });
}