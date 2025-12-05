/// File: group_creating.dart
/// Screen for creating a new travel group
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../widgets/calendar_card.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class GroupCreatingScreen extends StatefulWidget {
  final String? destinationName;
  final VoidCallback? onBack;

  const GroupCreatingScreen({
    Key? key,
    this.destinationName,
    this.onBack,
  }) : super(key: key);

  @override
  State<GroupCreatingScreen> createState() => _GroupCreatingScreenState();
}

class _GroupCreatingScreenState extends State<GroupCreatingScreen>
    with TickerProviderStateMixin {
  // Key to locate the date field position for popover
  final GlobalKey _dateFieldKey = GlobalKey();

  // Dữ liệu nhóm
  int _numberOfPeople = 10;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime _focusedDay = DateTime.now();
  bool _isCalendarVisible = false;
  String _groupName = 'Nhóm của bạn';
  File? _groupAvatar;
  
  // City and dates from profile
  String? _profileCity;
  // (profile start/end stored directly in _selectedStartDate/_selectedEndDate)

  // Sở thích và lộ trình (mutable so we can load from profile)
  List<String> _selectedInterests = [];
  List<String> _itineraryItems = [];

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _stateTransitionController;
  // Note: we use controllers directly for animations; specific Animation objects removed
  late Animation<Color?> _circleColorAnimation;

  int _currentState = 0; // 0: Idle, 1: Processing, 2: Success
  double _dragOffset = 0;
  final double _maxDragOffset = 260;

  @override
  void initState() {
    super.initState();
    
    // Load profile data immediately when screen opens
    _loadProfileData();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _stateTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Using _slideController directly for value-driven UI updates

    _circleColorAnimation = ColorTween(
      begin: const Color(0xFFF7F3E8),
      end: const Color(0xFFCD7F32),
    ).animate(_slideController);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _stateTransitionController.dispose();
    super.dispose();
  }

  void _handleSlideComplete() async {
    setState(() => _currentState = 1);

    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('session_expired'.tr())),
          );
        }
        setState(() => _currentState = 0);
        return;
      }

      String? imageUrl;
      if (_groupAvatar != null) {
        imageUrl = await _uploadAvatarViaHTTP(_groupAvatar!, token);
        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('upload_avatar_failed'.tr())),
            );
          }
          setState(() => _currentState = 0);
          return;
        }
      }

      final created = await _createGroup(_groupName, _numberOfPeople, imageUrl, token);
      if (!mounted) return;

      if (created) {
        setState(() => _currentState = 2);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && widget.onBack != null) widget.onBack!();
      } else {
        setState(() => _currentState = 0);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('create_group_failed'.tr())),
          );
        }
      }
    } catch (e) {
      debugPrint('Create group error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cannot_connect_server'.tr())),
        );
      }
      setState(() => _currentState = 0);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _groupAvatar = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadAvatarViaHTTP(File avatarFile, String token, {String? oldFileUrl}) async {
    try {
      final fileBytes = await avatarFile.readAsBytes();
      const supabaseUrl = ApiConfig.supabaseUrl;
      const bucket = 'avatar_group';

      if (oldFileUrl != null && oldFileUrl.trim().isNotEmpty) {
        try {
          final uri = Uri.parse(oldFileUrl);
          final segments = uri.pathSegments;
          int idx = segments.indexOf('public');
          String? objectPath;
          if (idx != -1 && idx + 2 < segments.length) {
            objectPath = segments.sublist(idx + 2).join('/');
          } else {
            idx = segments.indexOf(bucket);
            if (idx != -1 && idx + 1 < segments.length) {
              objectPath = segments.sublist(idx + 1).join('/');
            }
          }

          if (objectPath != null && objectPath.isNotEmpty) {
            final deleteUri = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$objectPath');
            debugPrint('Deleting old file at: $deleteUri');
            final delResp = await http.delete(
              deleteUri,
              headers: {
                'Authorization': 'Bearer $token',
                'apikey': ApiConfig.supabaseAnonKey,
                'Content-Type': 'application/json',
              },
            );
            debugPrint('Delete status: ${delResp.statusCode} body: ${delResp.body}');
          }
        } catch (e) {
          debugPrint('Old file delete failed: $e');
        }
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${avatarFile.path.split(Platform.pathSeparator).last}';
      final uploadUri = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$fileName');

      debugPrint('Uploading to: $uploadUri');

      final resp = await http.post(
        uploadUri,
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': ApiConfig.supabaseAnonKey,
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      debugPrint('Upload status: ${resp.statusCode} body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucket/$fileName';
        debugPrint('Uploaded public URL: $publicUrl');
        return publicUrl;
      }

      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<bool> _createGroup(String name, int maxMembers, String? imageUrl, String token) async {
    try {
      final url = ApiConfig.getUri(ApiConfig.createGroup);
      final body = {
        'name': name,
        'max_members': maxMembers,
        'group_image_url': imageUrl ?? '',
      };
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      debugPrint('Create group status: ${resp.statusCode} body: ${resp.body}');

      if (resp.statusCode == 400) {
        try {
          final respBody = jsonDecode(resp.body) as Map<String, dynamic>;
          final detail = respBody['detail'] as String?;
          if (detail != null && detail.contains('Host')) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Thông báo'),
                  content: Text('Bạn đã có nhóm!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    )
                  ],
                ),
              );
            }
            return false;
          }
        } catch (e) {
          debugPrint('Error parsing 400 response: $e');
        }
      }
      
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('Create group error: $e');
      return false;
    }
  }

  void _showEditGroupNameDialog() {
    final controller = TextEditingController(text: _groupName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F3E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'set_group_name'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF000000),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'enter_group_name'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCC9A7), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB99668), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7F3E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              setState(() {
                _groupName = controller.text.isEmpty ? 'default_group_name'.tr() : controller.text;
              });
              Navigator.pop(context);
            },
            child: Text(
              'confirm_action'.tr(),
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildNumberOfPeople(),
                    const SizedBox(height: 16),
                    _buildLocationAndDate(),
                    const SizedBox(height: 24),
                    _buildInterestsSection(),
                    const SizedBox(height: 24),
                    _buildItinerarySection(),
                    const SizedBox(height: 32),
                    _buildSliderButton(),
                    const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Calendar overlay (mirrors HomePage implementation)
            if (_isCalendarVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _isCalendarVisible = false),
                  child: Container(
                    color: Colors.black.withAlpha((0.5 * 255).toInt()),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {},
                      child: CalendarCard(
                        focusedDay: _focusedDay,
                        initialRangeStart: _selectedStartDate,
                        initialRangeEnd: _selectedEndDate,
                        onClose: () {
                          setState(() {
                            _isCalendarVisible = false;
                          });
                        },
                        accentColor: const Color(0xFFB99668),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/create_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF000000),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'create_group_title'.tr(),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF18900),
                              decoration: TextDecoration.none,
                              fontFamily: 'Alumni Sans',
                              height: 0.965,
                              letterSpacing: -0.04 * 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const Spacer(),

              // Avatar và tên nhóm
              Column(
                children: [
                  // Avatar với khả năng upload
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: _groupAvatar == null ? const Color(0xFFDCC9A7) : null,
                            image: _groupAvatar != null
                                ? DecorationImage(
                                    image: FileImage(_groupAvatar!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _groupAvatar == null
                              ? const Icon(
                                  Icons.group,
                                  size: 60,
                                  color: Color(0xFF8A724C),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF18900),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showEditGroupNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _groupName,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF7F3E8),
                            decoration: TextDecoration.none,
                            fontFamily: 'Alegreya',
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          color: Color(0xFFE5CDB1),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberOfPeople() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showNumberPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_numberOfPeople ${'people_count'.tr()}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/group_creating/chevron-down.jpg',
                  width: 14,
                  height: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndDate() {
    String dateDisplay = 'choose_date'.tr();
    
    print('🔍 _buildLocationAndDate called:');
    print('  - _selectedStartDate: $_selectedStartDate');
    print('  - _selectedEndDate: $_selectedEndDate');
    
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final format = DateFormat('dd/MM');
      dateDisplay = '${format.format(_selectedStartDate!)} - ${format.format(_selectedEndDate!)}';
      print('  - dateDisplay: $dateDisplay');
    } else if (_selectedStartDate != null) {
      final format = DateFormat('dd/MM');
      dateDisplay = format.format(_selectedStartDate!);
      print('  - dateDisplay (start only): $dateDisplay');
    }
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                  color: Color(0xFF8A724C),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _profileCity ?? widget.destinationName ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showCalendarDialog,
            child: Container(
              key: _dateFieldKey,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/group_creating/calendar_today.jpg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: (_selectedStartDate != null && _selectedEndDate != null)
                            ? const Color(0xFF000000)
                            : const Color(0xFF8A724C),
                        fontWeight: (_selectedStartDate != null && _selectedEndDate != null)
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7F3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCC9A7), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'interests'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9A7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$interest',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCC9A7), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'itinerary'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          ..._itineraryItems.map((item) => _buildItineraryItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderButton() {
    if (_currentState == 0) {
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dx;
            _dragOffset = _dragOffset.clamp(0.0, _maxDragOffset);
            _slideController.value = _dragOffset / _maxDragOffset;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset >= _maxDragOffset * 0.8) {
            setState(() {
              _dragOffset = _maxDragOffset;
            });
            _handleSlideComplete();
          } else {
            setState(() {
              _dragOffset = 0;
            });
            _slideController.animateTo(0);
          }
        },
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFFB99668), const Color(0xFFCD7F32),
                        _slideController.value)!,
                    Color.lerp(const Color(0xFFEDE2CC), const Color(0xFFDCC9A7),
                        _slideController.value)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Text "Trượt để tạo" → "Tiến hành"
                  AnimatedOpacity(
                    opacity: 1 - _slideController.value,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.translate(
                      offset: Offset(_dragOffset * 0.5, 0),
                      child: Text(
                        'slide_to_create'.tr(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _slideController.value,
                    duration: const Duration(milliseconds: 200),
                    child: Transform.translate(
                      offset: Offset(-_maxDragOffset * (1 - _slideController.value) * 0.5, 0),
                      child: Text(
                        'proceed'.tr(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Alegreya',
                        ),
                      ),
                    ),
                  ),

                  // Sliding circle
                  Positioned(
                    left: 4 + _dragOffset,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: _circleColorAnimation.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else if (_currentState == 1) {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFDCC9A7)],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'proceed'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD7F32),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB64B12), Color(0xFFCD7F32)],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'success_created'.tr(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Alegreya',
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFE49342),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showCalendarDialog() {
    setState(() {
      _isCalendarVisible = true;
    });
  }

  void _showNumberPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempNumber = _numberOfPeople;
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F3E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'select_people_count'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF000000),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        color: const Color(0xFFB99668),
                        onPressed: tempNumber > 1
                            ? () {
                          setDialogState(() {
                            tempNumber--;
                          });
                        }
                            : null, // Disable khi = 1
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFB99668), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$tempNumber',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        color: const Color(0xFFB99668),
                        onPressed: tempNumber < 10
                            ? () {
                          setDialogState(() {
                            tempNumber++;
                          });
                        }
                            : null, // ← Disable khi đạt 10
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tempNumber / 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: tempNumber == 10 ? Colors.red : Colors.grey,
                      fontWeight: tempNumber == 10 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(), style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB99668),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                setState(() {
                  _numberOfPeople = tempNumber;
                });
                Navigator.pop(context);
              },
              child: Text(
                'confirm_action'.tr(),
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
    try {
      debugPrint('Loading profile data for group creation...');

      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        debugPrint('No token available');
        return;
      }

      final url = ApiConfig.getUri(ApiConfig.userProfile);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Profile response status: ${response.statusCode}');
      debugPrint('Profile response body: ${response.body}');

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _profileCity = data['preferred_city']?.toString()
                    ?? widget.destinationName;

        final interestsRaw = data['interests'];
        if (interestsRaw is List) {
          _selectedInterests = interestsRaw
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        final itineraryRaw = data['itinerary'];
        if (itineraryRaw != null) {
          if (itineraryRaw is Map) {
            final entries = itineraryRaw.entries.toList();
            entries.sort((a, b) {
              final ai = int.tryParse(a.key.toString()) ?? 0;
              final bi = int.tryParse(b.key.toString()) ?? 0;
              return ai.compareTo(bi);
            });
            _itineraryItems = entries.map((e) => e.value?.toString() ?? '').where((s) => s.isNotEmpty).toList();
          } else if (itineraryRaw is List) {
            _itineraryItems = itineraryRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          }
        }

        final travelDatesRaw = data['travel_dates'];
        debugPrint('Raw travel_dates from API: $travelDatesRaw (type: ${travelDatesRaw.runtimeType})');

        if (travelDatesRaw != null && travelDatesRaw.toString().trim().isNotEmpty) {
          _parseTravelDates(travelDatesRaw.toString());
        } else {
          _selectedStartDate = null;
          _selectedEndDate = null;
        }
      });

      debugPrint('✅ Profile loaded successfully for group creation');
      debugPrint('   City: $_profileCity');
      debugPrint('   Dates: $_selectedStartDate → $_selectedEndDate');
      debugPrint('   Interests: $_selectedInterests');
      debugPrint('   Itinerary: $_itineraryItems');

    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  void _parseTravelDates(String dateRange) {
    try {
      String s = dateRange.trim();

      if (s.contains('lower') && s.contains('upper')) {
        final cleaned = s.replaceAll('{', '').replaceAll('}', '').replaceAll(' ', '');
        String? lower;
        String? upper;

        final parts = cleaned.split(',');
        for (var part in parts) {
          if (part.startsWith('lower:')) lower = part.substring(6);
          if (part.startsWith('upper:')) upper = part.substring(6);
        }

        if (lower != null && upper != null) {
          _selectedStartDate = DateTime.tryParse(lower);
          _selectedEndDate = DateTime.tryParse(upper);
          if (_selectedStartDate != null && _selectedEndDate != null) {
            debugPrint('Parsed travel_dates (JSON format): $_selectedStartDate → $_selectedEndDate');
            return;
          }
        }
      }

      if (s.startsWith('[') && s.endsWith(')')) {
        final cleaned = s.substring(1, s.length - 1);
        final parts = cleaned.split(',');
        if (parts.length == 2) {
          final start = DateTime.tryParse(parts[0].trim());
          final end = DateTime.tryParse(parts[1].trim());
          if (start != null && end != null) {
            _selectedStartDate = start;
            _selectedEndDate = end;
            debugPrint('Parsed travel_dates (bracket format): $start → $end');
            return;
          }
        }
      }

      if (s.startsWith('"') && s.endsWith('"')) {
        s = s.substring(1, s.length - 1);
        return _parseTravelDates(s);
      }

      final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}');
      final matches = dateRegex.allMatches(s).toList();
      if (matches.length >= 2) {
        final start = DateTime.tryParse(matches[0].group(0)!);
        final end = DateTime.tryParse(matches[1].group(0)!);
        if (start != null && end != null) {
          _selectedStartDate = start;
          _selectedEndDate = end;
          debugPrint('Parsed travel_dates (fallback regex): $start → $end');
          return;
        }
      }

      debugPrint('⚠️ Cannot parse travel_dates: $dateRange');
      _selectedStartDate = null;
      _selectedEndDate = null;

    } catch (e) {
      debugPrint('❌ Exception when parsing travel_dates: $e');
      _selectedStartDate = null;
      _selectedEndDate = null;
    }
  }
}
