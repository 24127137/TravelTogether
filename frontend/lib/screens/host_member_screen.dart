import 'package:flutter/material.dart';
import '../widgets/out_group_dialog.dart';

class MemberScreenHost extends StatefulWidget {
  final String groupName;
  final int currentMembers;
  final int maxMembers;
  final List<Member> members;
  final List<PendingRequest> pendingRequests;

  const MemberScreenHost({
    super.key,
    required this.groupName,
    required this.currentMembers,
    required this.maxMembers,
    required this.members,
    required this.pendingRequests,
  });

  @override
  State<MemberScreenHost> createState() => _MemberScreenHostState();
}

class _MemberScreenHostState extends State<MemberScreenHost> {
  bool _showMembers = true;
  String _searchQuery = '';
  final Set<String> _selectedRequests = <String>{};
  late List<Member> _filteredMembers;
  late List<PendingRequest> _filteredRequests;

  @override
  void initState() {
    super.initState();
    _updateFilteredLists();
  }

  void _updateFilteredLists() {
    _filteredMembers = widget.members
        .where((member) =>
    member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        member.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    _filteredRequests = widget.pendingRequests
        .where((request) =>
        request.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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

  void _approveSelectedRequests() {
    if (_selectedRequests.isEmpty) return;

    setState(() {
      // Thêm các requests được chọn vào danh sách members
      final approvedRequests = widget.pendingRequests
          .where((request) => _selectedRequests.contains(request.id))
          .toList();

      for (var request in approvedRequests) {
        widget.members.add(Member(
          id: request.id,
          name: request.name,
          email: "${request.name.toLowerCase().replaceAll(' ', '.')}@example.com",
          avatarUrl: "https://randomuser.me/api/portraits/men/${widget.members.length + 1}.jpg",
        ));
      }

      // Xóa khỏi pending requests
      widget.pendingRequests.removeWhere(
            (request) => _selectedRequests.contains(request.id),
      );

      _selectedRequests.clear();
      _updateFilteredLists();
    });
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
              // Header
              _buildHeader(),

              // Member count
              _buildMemberCount(),

              // Tab buttons
              _buildTabButtons(),

              // Search bar
              _buildSearchBar(),

              // Content list
              Expanded(
                child: _showMembers ? _buildMembersList() : _buildPendingList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      child: Row(
        children: [
          // Back button
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

          // Group name
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

          // Exit/Approve button
          GestureDetector(
            onTap: () {
              OutGroupDialog.show(
                context,
                isHost: true,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: ShapeDecoration(
                color: _showMembers
                    ? const Color(0xFFF6F6F8)
                    : (_selectedRequests.isNotEmpty
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF6F6F8)),
                shape: const CircleBorder(),
              ),
              child: Icon(
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

  int get currentMemberCount => widget.members.length;

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
          // Members tab
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

          // Pending tab
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
          onDismissed: (direction) {
            setState(() {
              widget.members.remove(member);
              _updateFilteredLists();
            });
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
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(member.avatarUrl),
          ),

          const SizedBox(width: 16),

          // Member info
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final request = _filteredRequests[index];
        return Dismissible(
          key: Key(request.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            setState(() {
              widget.pendingRequests.remove(request);
              _selectedRequests.remove(request.id);
              _updateFilteredLists();
            });
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
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFDCC9A7),
            child: const Icon(
              Icons.person,
              size: 30,
              color: Color(0xFF666666),
            ),
          ),

          const SizedBox(width: 16),

          // Request info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Tên và rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.name,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 18,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          request.rating.toString(),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Keywords
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: request.keywords.take(3).map((keyword) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDCC9A7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          keyword,
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 12,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Selection checkbox
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
}

// Data models
class Member {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}

class PendingRequest {
  final String id;
  final String name;
  final double rating;
  final List<String> keywords;

  PendingRequest({
    required this.id,
    required this.name,
    required this.rating,
    required this.keywords,
  });
}
