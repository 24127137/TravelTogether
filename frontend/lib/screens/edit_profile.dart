import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String birthDate;
  final String gender;
  final String description;
  final List<String> interests;
  final File? avatar;
  final String email;
  final String accessToken;

  const EditProfilePage({
    super.key,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.description,
    required this.interests,
    required this.email,
    required this.accessToken,
    this.avatar,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late DateTime? _birthDate;
  late String _gender;
  late List<String> _selectedInterests;
  File? _avatar;

  final Color boxColor = Colors.white.withValues(alpha: 0.9);
  final Color labelColor = Colors.black;
  final String country = "Vietnam";

  final List<Map<String, String>> _allInterests = [
    {'title': 'Văn hóa', 'image': 'assets/images/interests/culture.jpg'},
    {'title': 'Ẩm thực', 'image': 'assets/images/interests/food.jpg'},
    {'title': 'Nhiếp ảnh', 'image': 'assets/images/interests/photo.jpg'},
    {'title': 'Leo núi', 'image': 'assets/images/interests/trekking.jpg'},
    {'title': 'Tắm biển', 'image': 'assets/images/interests/beach.jpg'},
    {'title': 'Mua sắm', 'image': 'assets/images/interests/shopping.jpg'},
    {'title': 'Tham quan', 'image': 'assets/images/interests/sightseeing.jpg'},
    {'title': 'Nghỉ dưỡng', 'image': 'assets/images/interests/resort.jpg'},
    {'title': 'Lễ hội', 'image': 'assets/images/interests/festival.jpg'},
    {'title': 'Cafe', 'image': 'assets/images/interests/cafe.jpg'},
    {'title': 'Homestay', 'image': 'assets/images/interests/homestay.jpg'},
    {'title': 'Ngắm cảnh', 'image': 'assets/images/interests/view.jpg'},
    {'title': 'Cắm trại', 'image': 'assets/images/interests/camping.jpg'},
    {'title': 'Du thuyền', 'image': 'assets/images/interests/cruise.jpg'},
    {'title': 'Động vật', 'image': 'assets/images/interests/animals.jpg'},
    {'title': 'Mạo hiểm', 'image': 'assets/images/interests/thrilling.jpg'},
    {'title': 'Phượt', 'image': 'assets/images/interests/backpacking.jpg'},
    {'title': 'Đặc sản', 'image': 'assets/images/interests/specialty.jpg'},
    {'title': 'Vlog', 'image': 'assets/images/interests/vlog.jpg'},
    {'title': 'Chèo sup', 'image': 'assets/images/interests/rowing.jpg'},
    {'title': 'Khác', 'image': ''},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _descriptionController = TextEditingController(text: widget.description);
    _emailController = TextEditingController(text: widget.email);
    _gender = widget.gender;
    _selectedInterests = List.from(widget.interests);
    _avatar = widget.avatar;

    try {
      final parts = widget.birthDate.split('/');
      if (parts.length == 3) {
        _birthDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      _birthDate = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final url = ApiConfig.getUri(ApiConfig.userProfile);

    final genderMap = {
      'Nam': 'male',
      'Nữ': 'female',
      'Khác': 'other',
    };

    final body = jsonEncode({
      'fullname': _nameController.text,
      'gender': genderMap[_gender] ?? 'other', 
      'interests': _selectedInterests,
    });

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pop(context, {
          'name': data['fullname'],
          'nickname': _descriptionController.text,
          'gender': data['gender'],
          'birthday': data['birthday'], 
          'interests': List<String>.from(data['interests']),
          'avatar': _avatar,
        });
      } else {
        print('Lỗi server: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể kết nối đến server')),
      );
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8A724C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF8A724C),
                textStyle: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _pickGender() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Chọn giới tính',
          style: TextStyle(
            fontFamily: 'WorkSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGenderOption('Nam'),
            _buildGenderOption('Nữ'),
            _buildGenderOption('Khác'),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _gender = result);
    }
  }

  Widget _buildGenderOption(String value) {
    return ListTile(
      title: Text(
        value,
        style: const TextStyle(
          fontFamily: 'WorkSans',
          fontWeight: FontWeight.w500,
        ),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: _gender,
        onChanged: (v) {
          Navigator.pop(context, v);
        },
        activeColor: const Color(0xFF8A724C),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }

  void _pickInterests() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _InterestsDialog(
        allInterests: _allInterests,
        selectedInterests: List.from(_selectedInterests),
      ),
    );

    if (result != null) {
      setState(() => _selectedInterests = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 178, 138, 100),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile_page_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      child: Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(200, 185, 150, 104),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _nameController.text.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'WorkSans',
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    country.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'WorkSans',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 5,
                              left: 5,
                              child: _buildCircleButton(
                                icon: Icons.arrow_back_ios_new,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: _buildCircleButton(
                                icon: Icons.check,
                                onPressed: _saveProfile,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(220, 138, 114, 76),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 50),
                              buildTextField("Họ và tên", _nameController),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildClickableField(
                                      "Ngày sinh",
                                      _birthDate != null
                                          ? "${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}"
                                          : "Chọn ngày sinh",
                                      _pickDate,
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                  Expanded(
                                    child: buildClickableField(
                                      "Giới tính",
                                      _gender,
                                      _pickGender,
                                    ),
                                  ),
                                ],
                              ),
                              buildTextField("Email", _emailController),
                              const SizedBox(height: 10),
                              buildInterestsField(),
                              const SizedBox(height: 15),
                              buildTextField("Mô tả bản thân", _descriptionController, maxLines: 3),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 144,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: _avatar != null
                          ? FileImage(_avatar!)
                          : const AssetImage('assets/images/logo.jpg') as ImageProvider,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 14,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildClickableField(String label, String value, VoidCallback onTap, {bool showFullBox = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 14,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInterestsField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sở thích du lịch",
            style: TextStyle(
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickInterests,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _selectedInterests.length; i += 2)
                    Padding(
                      padding: EdgeInsets.only(bottom: i + 2 < _selectedInterests.length ? 18 : 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildInterestBox(_selectedInterests[i]),
                          if (i + 1 < _selectedInterests.length)
                            buildInterestBox(_selectedInterests[i + 1]),
                        ],
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

  Widget buildInterestBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 32,
      width: 125,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 237, 226, 204),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color.fromARGB(255, 185, 150, 104),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tag,
            size: 16,
            color: Color.fromARGB(255, 37, 37, 37),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'WorkSans',
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8A724C),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(5),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _InterestsDialog extends StatefulWidget {
  final List<Map<String, String>> allInterests;
  final List<String> selectedInterests;

  const _InterestsDialog({
    required this.allInterests,
    required this.selectedInterests,
  });

  @override
  State<_InterestsDialog> createState() => _InterestsDialogState();
}

class _InterestsDialogState extends State<_InterestsDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 249, 233, 208),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text(
              'Chọn ít nhất 3 sở thích du lịch của bạn',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'WorkSans',
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: widget.allInterests.length,
                itemBuilder: (context, index) {
                  final interest = widget.allInterests[index];
                  final isSelected = _tempSelected.contains(interest['title']);
                  final imagePath = (interest['image'] ?? '').trim();
                  final hasImage = imagePath.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _tempSelected.remove(interest['title']);
                        } else {
                          _tempSelected.add(interest['title']!);
                        }
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF8A724C)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: hasImage
                                      ? Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              alignment: Alignment.center,
                                              child: Text(
                                                interest['title']!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontFamily: 'WorkSans',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          alignment: Alignment.center,
                                          child: Text(
                                            interest['title']!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: 'WorkSans',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8A724C),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            interest['title']!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'WorkSans',
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF8A724C)
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _tempSelected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A724C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'WorkSans',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
