import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
        title: Text('location_permission_required'.tr()),
        content: Text('location_permission_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              Future.delayed(const Duration(seconds: 1), _checkLocationPermission);
            },
            child: Text('open_settings'.tr()),
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
        title: Text(
          'emergency_pin_title'.tr(),
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            fontFamily: 'Alumni Sans',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5EFE6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text(
                'emergency_pin_title'.tr(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Alumni Sans',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'emergency_pin_desc'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Alegreya',
                ),
              ),
              const SizedBox(height: 32),
              _buildFeatureItem(
                Icons.notifications_active,
                'send_sos'.tr(),
                'send_sos_desc'.tr(),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.location_on,
                'share_location'.tr(),
                'share_location_desc'.tr(),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.visibility_off,
                'stealth_mode'.tr(),
                'stealth_mode_desc'.tr(),
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
                                ? 'location_enabled'.tr()
                                : 'enable_location'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Alegreya',
                            ),
                          ),
                          Text(
                            _locationEnabled
                                ? 'location_enabled_desc'.tr()
                                : 'enable_location_desc'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontFamily: 'Alegreya',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _locationEnabled,
                      onChanged: _isChecking ? null : _toggleLocationPermission,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
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
                    fontFamily: 'Alegreya',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'Alegreya',
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