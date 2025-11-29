import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

  // Sample data - sẽ thay bằng data từ backend
  List<GroupApplication> applications = [
    GroupApplication(
      id: '1',
      groupName: 'HANOI TRONG TÔI',
      avatar: 'https://placehold.co/60x60',
      status: ApplicationStatus.pending,
    ),
    GroupApplication(
      id: '2',
      groupName: '2 lần 1 tháng',
      avatar: 'https://placehold.co/60x60',
      status: ApplicationStatus.accepted,
    ),
    GroupApplication(
      id: '3',
      groupName: 'Nghìn năm văn vở',
      avatar: 'https://placehold.co/60x60',
      status: ApplicationStatus.rejected,
    ),
    GroupApplication(
      id: '4',
      groupName: 'BANA HILL de Da Nang',
      avatar: 'https://placehold.co/60x60',
      status: ApplicationStatus.pending,
    ),
  ];

  // Filtered list used for display (updated by search)
  List<GroupApplication> _filteredApplications = [];

  @override
  void initState() {
    super.initState();
    // initialize filtered list from applications
    _filteredApplications = List.from(applications);
  }

  void _deleteApplication(String id) {
    setState(() {
      applications.removeWhere((app) => app.id == id);
      // also update filtered list
      _filteredApplications.removeWhere((app) => app.id == id);
    });
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
                    child: _filteredApplications.isEmpty
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
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
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

class ApplicationCard extends StatelessWidget {
  final GroupApplication application;
  final VoidCallback onDelete;

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
      onDismissed: (direction) => onDelete(),
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
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(application.avatar),
                  fit: BoxFit.cover,
                ),
              ),
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

// Model classes
enum ApplicationStatus {
  pending,
  accepted,
  rejected,
}

class GroupApplication {
  final String id;
  final String groupName;
  final String avatar;
  final ApplicationStatus status;

  GroupApplication({
    required this.id,
    required this.groupName,
    required this.avatar,
    required this.status,
  });
}
