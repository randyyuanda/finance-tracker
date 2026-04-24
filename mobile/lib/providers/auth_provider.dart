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

  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
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

  Future<bool> updateProfile(String name) async {
    try {
      final res = await ApiClient.dio.patch('/auth/profile', data: {'name': name});
      _user = User.fromJson(res.data['user'] ?? res.data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = parseError(e);
      notifyListeners();
      return false;
    }
  }
}
