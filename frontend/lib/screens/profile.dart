import 'package:flutter/material.dart';
import 'dart:io';
import 'edit_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String accessToken;

  const ProfilePage({super.key, required this.accessToken});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? avatarImage;

  String country = "Vietnam";
  String fullName = ""; 
  String birthDate = "01/01/2000";
  String gender = "";
  String email = "";
  String description =
      "";
  List<String> interests = [];

  final Color bgColor = const Color.fromARGB(255, 178, 138, 100);
  final Color boxColor = const Color.fromARGB(150, 250, 247, 239);
  final Color labelColor = const Color.fromARGB(255, 0, 0, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(200, 185, 150, 104),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const Alignment(0, -0.3), 
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 70),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        fullName.toUpperCase(),
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
                            ),

                            Positioned(
                              top: 5,
                              left: 5,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF8A724C),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white, size: 15),
                                  onPressed: () => Navigator.pop(context),
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF8A724C),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 16),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfilePage(
                                          fullName: fullName,
                                          email: email,
                                          description: description,
                                          gender: gender,
                                          birthDate: birthDate,
                                          interests: interests,
                                          avatar: avatarImage,
                                          accessToken: widget.accessToken,
                                        ),
                                      ),
                                    );

                                    if (result != null) {
                                      await _fetchProfile(); 
                                    }
                                  },
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(),
                                ),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(220, 138, 114, 76),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 50),
                              buildDisplayBox("Họ và tên", fullName),
                              Row(
                                children: [
                                  Expanded(
                                      child:
                                          buildDisplayBox("Ngày sinh", birthDate)),
                                  const SizedBox(width: 48),
                                  Expanded(
                                      child: buildDisplayBox("Giới tính", gender)),
                                ],
                              ),
                              buildDisplayBox("Email", email),
                              const SizedBox(height: 10),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < interests.length; i += 2)
                                      Padding(
                                        padding: EdgeInsets.only(
                                            bottom:
                                                i + 2 < interests.length ? 18 : 0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            buildInterestBox(interests[i]),
                                            if (i + 1 < interests.length)
                                              buildInterestBox(interests[i + 1]),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              buildDisplayBox(
                                  "Mô tả bản thân", description,
                                  maxLines: 3),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarImage != null
                          ? FileImage(avatarImage!)
                          : const AssetImage('assets/images/logo.jpg')
                              as ImageProvider,
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

  Widget buildDisplayBox(String label, String value, {int maxLines = 1}) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
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
            style: TextStyle(
              fontFamily: 'WorkSans',
              fontSize: 13,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchProfile() async {
    final url = Uri.parse('http://10.0.2.2:8000/users/me');
    
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.accessToken}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fullName = data['fullname'] ?? fullName;
          email = data['email'] ?? email;
          description = data['description'] ?? description;
          gender = data['gender'] ?? gender;
          birthDate = data['birth_date'] ?? birthDate;
          interests = List<String>.from(data['interests'] ?? interests);
        });
      } else {
        print('Không thể load profile: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gọi API profile: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }
}
