import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/services/database_helper.dart';

class AuthProvider with ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  bool _isOnboarded = false;
  bool _isLockEnabled = false;
  bool _useBiometrics = false;
  bool _isAuthenticated = false; // Internal session state (locked/unlocked)

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboarded => _isOnboarded;
  bool get isLockEnabled => _isLockEnabled;
  bool get useBiometrics => _useBiometrics;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;
      _isLockEnabled = prefs.getBool('is_lock_enabled') ?? false;
      _useBiometrics = prefs.getBool('use_biometrics') ?? false;

      // If lock is disabled, user is automatically "authenticated" for the session
      if (!_isLockEnabled) {
        _isAuthenticated = true;
      }

      // Load local user profile if exists
      final username = prefs.getString('user_name');
      if (username != null) {
        _user = await _dbHelper.getUser(username);
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setOnboardingComplete({
    required String name,
    String? email,
    double? budget,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Save to Local DB
      final userId = await _dbHelper.upsertUser(
        username: name.toLowerCase().replaceAll(' ', '_'),
        fullName: name,
        email: email,
        defaultBudget: budget,
      );

      // 2. Update Preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString(
          'user_name', name.toLowerCase().replaceAll(' ', '_'));

      _isOnboarded = true;
      _isAuthenticated = true; // First time entry doesn't require lock
      _user = {
        'id': userId,
        'username': name.toLowerCase().replaceAll(' ', '_'),
        'fullName': name,
        'email': email,
        'defaultBudget': budget,
      };

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setAppLock(String pin, bool useBiometrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_lock_enabled', true);
      if (pin.isNotEmpty) {
        await prefs.setString('app_pin', pin);
      }
      await prefs.setBool('use_biometrics', useBiometrics);

      _isLockEnabled = true;
      _useBiometrics = useBiometrics;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBiometrics(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_biometrics', enabled);
      _useBiometrics = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_lock_enabled', false);
    await prefs.remove('app_pin');
    _isLockEnabled = false;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('app_pin');

    if (savedPin == pin) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock Expenze',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Reset everything
    _user = null;
    _isOnboarded = false;
    _isLockEnabled = false;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    double? defaultBudget,
  }) async {
    if (_user?['id'] == null) return;

    try {
      await _dbHelper.updateUserProfile(_user!['id'], {
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        if (defaultBudget != null) 'default_budget': defaultBudget,
      });

      final updatedUser = await _dbHelper.getUser(_user!['username']);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Update failed';
      notifyListeners();
    }
  }

  void clearError() => {_error = null, notifyListeners()};
}
