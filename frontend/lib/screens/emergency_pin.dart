import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyPinInfoScreen extends StatefulWidget {
  const EmergencyPinInfoScreen({super.key});

  @override
  State<EmergencyPinInfoScreen> createState() => _EmergencyPinInfoScreenState();
}

class _EmergencyPinInfoScreenState extends State<EmergencyPinInfoScreen> {
  bool _locationEnabled = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    try {
      final permission = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _locationEnabled = permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _toggleLocationPermission(bool value) async {
    // Nếu đang bật -> tắt (mở Settings để tắt)
    if (value == false && _locationEnabled) {
      await Geolocator.openAppSettings();
      Future.delayed(const Duration(seconds: 1), _checkLocationPermission);
      return;
    }

    // Nếu đang tắt -> bật (xin quyền)
    if (value == true && !_locationEnabled) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ vị trí trong cài đặt'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn đã từ chối quyền truy cập vị trí'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        if (permission == LocationPermission.deniedForever) {
          _showPermissionDialog();
          return;
        }
      }

      await _checkLocationPermission();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền truy cập vị trí'),
        content: const Text(
          'Để sử dụng tính năng khẩn cấp, bạn cần cấp quyền truy cập vị trí trong cài đặt hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              Future.delayed(const Duration(seconds: 1), _checkLocationPermission);
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text(
          "Mã PIN khẩn cấp",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            fontFamily: 'WorkSans',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency,
                size: 60,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Mã PIN khẩn cấp",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'WorkSans',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Thiết lập mã PIN khẩn cấp để bảo vệ bạn trong tình huống nguy hiểm",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'WorkSans',
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureItem(
              Icons.notifications_active,
              "Gửi thông báo SOS",
              "Tự động gửi tin nhắn cảnh báo đến email liên hệ",
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.location_on,
              "Chia sẻ vị trí",
              "Gửi vị trí GPS hiện tại cho liên hệ khẩn cấp",
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.visibility_off,
              "Chế độ ẩn danh",
              "App hoạt động bình thường để không lộ tình huống",
            ),
            const SizedBox(height: 32),
            
            // Location permission toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _locationEnabled 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _locationEnabled 
                      ? Colors.green.withOpacity(0.3) 
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationEnabled ? Icons.location_on : Icons.location_off,
                    color: _locationEnabled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationEnabled 
                              ? 'Truy cập vị trí đã bật' 
                              : 'Bật truy cập vị trí',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                        Text(
                          _locationEnabled 
                              ? 'Vị trí sẽ được gửi khi khẩn cấp' 
                              : 'Cần thiết để gửi vị trí SOS',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontFamily: 'WorkSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _locationEnabled,
                    onChanged: _isChecking ? null : _toggleLocationPermission,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'WorkSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'WorkSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}