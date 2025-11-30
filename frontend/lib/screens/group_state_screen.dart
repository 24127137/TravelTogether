import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../config/api_config.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<GroupApplication> applications = [];
  List<GroupApplication> _filteredApplications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? accessToken = await AuthService.getValidAccessToken();

      final url = ApiConfig.getUri(ApiConfig.userProfile);

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final pendingRequests = data['pending_requests'] as List?;

        if (pendingRequests != null) {
          List<GroupApplication> tempApplications = [];

          for (var i = 0; i < pendingRequests.length; i++) {
            final item = pendingRequests[i];

            print('📦 Pending request item $i: $item');

            final requestId = item['id']?.toString() ?? '';
            final groupId = item['group_id']?.toString() ?? '';

            String uniqueId;
            if (groupId.isNotEmpty) {
              uniqueId = groupId;
            } else if (requestId.isNotEmpty) {
              uniqueId = requestId;
            } else {
              uniqueId = 'request_$i';
            }

            print('📦 Using ID: $uniqueId (request_id: "$requestId", group_id: "$groupId")');

            tempApplications.add(GroupApplication(
              id: uniqueId,
              groupId: groupId.isNotEmpty ? groupId : null,
              groupName: item['group_name']?.toString() ??
                  item['groupName']?.toString() ??
                  'Unknown Group',
              avatar: 'https://placehold.co/60x60',
              status: _parseStatus(item['status']),
            ));
          }

          await _loadGroupImages(tempApplications, accessToken!);

          setState(() {
            applications = tempApplications;
            _filteredApplications = List.from(applications);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching pending requests: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGroupImages(List<GroupApplication> apps, String accessToken) async {
    for (var app in apps) {
      if (app.groupId == null || app.groupId!.isEmpty) {
        print('⚠️ Skipping group image load for ${app.groupName}: no group_id');
        continue;
      }

      try {
        final groupUrl = Uri.parse('${ApiConfig.baseUrl}/groups/${app.groupId}/public-plan');

        print('🔍 Fetching group image for: ${app.groupName}');
        print('🔍 Group ID: ${app.groupId}');
        print('🔍 Full URL: $groupUrl');

        final response = await http.get(
          groupUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $accessToken",
          },
        );

        print('🔍 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final groupData = json.decode(utf8.decode(response.bodyBytes));
          print('🔍 Response data: $groupData');

          final groupImageUrl = groupData['group_image_url']?.toString();

          if (groupImageUrl != null && groupImageUrl.isNotEmpty) {
            app.avatar = groupImageUrl;
            print('✅ Loaded image for ${app.groupName}: $groupImageUrl');
          } else {
            print('⚠️ No group_image_url found for ${app.groupName}');
            print('⚠️ Available keys: ${groupData.keys.toList()}');
          }
        } else {
          print('⚠️ Failed to load group image for ${app.groupName}');
          print('⚠️ Status: ${response.statusCode}');
          print('⚠️ Body: ${response.body}');
        }
      } catch (e, stackTrace) {
        print('❌ Error loading group image for ${app.groupName}: $e');
        print('❌ StackTrace: $stackTrace');
      }
    }
  }

  ApplicationStatus _parseStatus(dynamic status) {
    if (status == null) return ApplicationStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'accepted':
      case 'approved':
        return ApplicationStatus.accepted;
      case 'rejected':
      case 'denied':
        return ApplicationStatus.rejected;
      case 'pending':
      default:
        return ApplicationStatus.pending;
    }
  }

  Future<void> _deleteApplication(String id) async {
    print('🗑️ === DELETE APPLICATION CALLED ===');
    print('🗑️ ID to delete: "$id"');
    print('🗑️ Current applications count: ${applications.length}');
    print('🗑️ Current applications IDs: ${applications.map((a) => '"${a.id}"').toList()}');

    final deletedAppIndex = applications.indexWhere((app) => app.id == id);

    if (deletedAppIndex == -1) {
      print('❌ Application with ID "$id" not found!');
      return;
    }

    final deletedApp = applications[deletedAppIndex];

    if (deletedApp.groupId == null || deletedApp.groupId!.isEmpty) {
      print('❌ No group_id found for this application');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_error'.tr() + ': No group ID'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('🗑️ Found item to delete: ${deletedApp.groupName}');
    print('🗑️ Group ID: ${deletedApp.groupId}');
    print('🗑️ At index: $deletedAppIndex');

    setState(() {
      applications.removeWhere((app) => app.id == id);
      _filteredApplications.removeWhere((app) => app.id == id);
    });

    print('🔄 UI updated - applications count: ${applications.length}');

    try {
      String? accessToken = await AuthService.getValidAccessToken();

      final url = ApiConfig.getUri(ApiConfig.groupRequestCancel);

      final bodyData = {
        'group_id': int.parse(deletedApp.groupId!),
      };

      print('🔄 Sending POST request to /groups/request-cancel');
      print('🔄 Body data: ${json.encode(bodyData)}');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: json.encode(bodyData),
      );

      print('🔄 Response status: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Successfully cancelled request');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('delete_success'.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ Failed to cancel request: ${response.statusCode}');
        print('❌ Response: ${response.body}');

        setState(() {
          applications.insert(deletedAppIndex, deletedApp);
          _filteredApplications = List.from(applications);
        });

        print('🔄 Rollback - applications count: ${applications.length}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('delete_failed'.tr()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error cancelling request: $e');

      setState(() {
        applications.insert(deletedAppIndex, deletedApp);
        _filteredApplications = List.from(applications);
      });

      print('🔄 Rollback after error - applications count: ${applications.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${"delete_error".tr()}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredApplications = List.from(applications);
      } else {
        _filteredApplications = applications
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
              // Header với nút back
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6F6F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                    const Spacer(),
                    // Nút refresh
                    GestureDetector(
                      onTap: _fetchPendingRequests,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6F6F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'group_list'.tr(),
                  style: TextStyle(
                    fontSize: 60,
                    fontFamily: 'Alumni Sans',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB99668),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  'pending_groups'.tr(),
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Alegreya',
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

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
                            hintStyle: TextStyle(color: Color(0xFF8A724C)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // List với padding bottom 100
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 130),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB99668),
                      ),
                    )
                        : _errorMessage != null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchPendingRequests,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB99668),
                            ),
                            child: Text('retry'.tr()),
                          ),
                        ],
                      ),
                    )
                        : _filteredApplications.isEmpty
                        ? Center(
                      child: Text(
                        'no_requests'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredApplications.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final app = _filteredApplications[index];
                        return ApplicationCard(
                          application: app,
                          onDelete: () async {
                            await _deleteApplication(app.id);
                          },
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

class ApplicationCard extends StatelessWidget {
  final GroupApplication application;
  final Future<void> Function() onDelete;

  const ApplicationCard({
    Key? key,
    required this.application,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(application.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('confirm_delete'.tr()),
              content: Text('delete_request_message'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('delete'.tr()),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await onDelete();
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB99668),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            // Avatar với loading indicator và error handling
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD9CBB3),
                image: DecorationImage(
                  image: NetworkImage(application.avatar),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    print('❌ Error loading image: $exception');
                  },
                ),
              ),
              child: application.avatar == 'https://placehold.co/60x60'
                  ? const Icon(
                Icons.group,
                size: 30,
                color: Colors.white,
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // Group name
            Expanded(
              child: Text(
                application.groupName,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 18,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Status badge
            _buildStatusBadge(application.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color bgColor;
    String text;
    IconData icon;

    switch (status) {
      case ApplicationStatus.accepted:
        bgColor = const Color(0xFF00674F);
        text = 'status_accepted'.tr();
        icon = Icons.check;
        break;
      case ApplicationStatus.rejected:
        bgColor = const Color(0xFFB64B12);
        text = 'status_rejected'.tr();
        icon = Icons.close;
        break;
      case ApplicationStatus.pending:
        bgColor = const Color(0xFFCD7F32);
        text = 'status_pending'.tr();
        icon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum ApplicationStatus {
  pending,
  accepted,
  rejected,
}

class GroupApplication {
  final String id;
  final String? groupId;
  final String groupName;
  String avatar;
  final ApplicationStatus status;

  GroupApplication({
    required this.id,
    this.groupId,
    required this.groupName,
    required this.avatar,
    required this.status,
  });
}