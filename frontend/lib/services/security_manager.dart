import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class SecurityManager {
  static final SecurityManager instance = SecurityManager._internal();

  SecurityManager._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> needsSetup() async {
    try {
      final status = await SecurityApiService.getSecurityStatus();
      return status.needsSetup;
    } catch (_) {
      return true;
    }
  }

  Future<bool> isEmergencyPinSet() async {
    return _prefs.getBool('emergency_pin_set') ?? false;
  }

  Future<void> setEmergencyPinSet(bool value) async {
    await _prefs.setBool('emergency_pin_set', value);
  }

  Future<void> incrementWrongAttempt() async {
    int count = _prefs.getInt('wrong_pin_wrong_count') ?? 0;
    count++;
    await _prefs.setInt('wrong_pin_wrong_count', count);
    if (count >= 5) {
      final lockUntil = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
      await _prefs.setInt('pin_lock_until', lockUntil);
    }
  }

  Future<void> resetWrongAttempt() async {
    await _prefs.remove('wrong_pin_wrong_count');
    await _prefs.remove('pin_lock_until');
  }

  Future<bool> isCurrentlyLocked() async {
    final timestamp = _prefs.getInt('pin_lock_until');
    if (timestamp == null) return false;
    final lockTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().isAfter(lockTime)) {
      await resetWrongAttempt();
      return false;
    }
    return true;
  }

  Future<int?> getRemainingLockSeconds() async {
    final timestamp = _prefs.getInt('pin_lock_until');
    if (timestamp == null) return null;
    final lockTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = lockTime.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : null;
  }
}