import 'package:flutter/material.dart';
import '../widgets/out_group_dialog.dart';

class MemberScreenMember extends StatefulWidget {
  final String groupName;
  final int currentMembers;
  final int maxMembers;
  final List<Member> members;

  const MemberScreenMember({
    super.key,
    required this.groupName,
    required this.currentMembers,
    required this.maxMembers,
    required this.members,
  });

  @override
  State<MemberScreenMember> createState() => _MemberScreenMemberState();
}

class _MemberScreenMemberState extends State<MemberScreenMember> {
  String _searchQuery = '';
  late List<Member> _filteredMembers;

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
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
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

              // Search bar
              _buildSearchBar(),

              // Members list
              Expanded(
                child: _buildMembersList(),
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
                  color: Colors.black,
                  fontSize: 28,
                  fontFamily: 'Lora',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),

          // Exit button
          GestureDetector(
            onTap: () {
              OutGroupDialog.show(
                context,
                isHost: false,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const ShapeDecoration(
                color: Color(0xFFF6F6F8),
                shape: CircleBorder(),
              ),
              child: const Icon(
                Icons.exit_to_app,
                size: 20,
                color: Colors.black,
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
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w400,
          ),
        ),
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
        return _buildMemberCard(member);
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
}

// Data model (sử dụng chung với Host)
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
