import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;
  bool _initialized = false;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final token = await Storage.getToken();
    if (token != null) {
      try {
        final res = await ApiClient.dio.get('/auth/me');
        _user = User.fromJson(res.data['user'] ?? res.data);
        _registerFcmToken();
      } catch (_) {
        await Storage.clearToken();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await ApiClient.dio.post('/auth/fcm-token', data: {'fcmToken': fcmToken});
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['token'];
      await Storage.saveToken(token);
      ApiClient.reset();
      _user = User.fromJson(res.data['user']);
      _loading = false;
      notifyListeners();
      _registerFcmToken();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, [String? phone]) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'contactNumber': phone,
      });
      final token = res.data['token'];
      await Storage.saveToken(token);
      ApiClient.reset();
      _user = User.fromJson(res.data['user']);
      _loading = false;
      notifyListeners();
      _registerFcmToken();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await Storage.clearToken();
    ApiClient.reset();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? avatar, String? language, String? currency}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatar != null) data['avatar'] = avatar;
      if (language != null) data['language'] = language;
      if (currency != null) data['currency'] = currency;
      
      final res = await ApiClient.dio.patch('/auth/profile', data: data);
      _user = User.fromJson(res.data['user'] ?? res.data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPassword(String password, String? phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = <String, dynamic>{'password': password};
      if (phone != null && phone.isNotEmpty) data['contactNumber'] = phone;

      final res = await ApiClient.dio.post('/auth/set-password', data: data);
      _user = User.fromJson(res.data['user'] ?? res.data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestOtp(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.dio.post('/auth/request-otp', data: {'email': email});
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
      final token = res.data['token'];
      await Storage.saveToken(token);
      ApiClient.reset();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/verify-email', data: {'otp': otp});
      _user = User.fromJson(res.data['user'] ?? res.data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.dio.post('/auth/resend-verification');
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/reset-password', data: {'password': password});
      _user = User.fromJson(res.data['user'] ?? res.data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
