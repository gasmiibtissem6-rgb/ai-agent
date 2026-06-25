import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isVerifying = false; // email verification state
  
  Map<String, String> _userProfile = {
    'fullName': 'Hamza',
    'email': 'hamza@example.com',
    'phone': '+216 90 123 4567',
    'address': 'Tunis, Tunisia',
    'accountType': 'Individual',
  };

  bool get isAuthenticated => _isAuthenticated;
  bool get isVerifying => _isVerifying;
  Map<String, String> get userProfile => _userProfile;

  Future<bool> login(String email, String password) async {
    // Mock login verification
    await Future.delayed(const Duration(milliseconds: 800));
    _isVerifying = true; // Go to verification screen first
    notifyListeners();
    return true;
  }

  Future<bool> register(String fullName, String email, String password, String accountType) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _userProfile = {
      'fullName': fullName,
      'email': email,
      'phone': '',
      'address': '',
      'accountType': accountType,
    };
    _isVerifying = true;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (otp.length == 6) {
      _isAuthenticated = true;
      _isVerifying = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String accountType,
  }) {
    _userProfile = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'accountType': accountType,
    };
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isVerifying = false;
    notifyListeners();
  }
}
