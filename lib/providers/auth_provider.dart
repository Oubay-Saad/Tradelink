import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isBooting = true;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isBooting => _isBooting;
  String? get error => _error;
  bool get isAuthenticated => _apiService.token != null;

  Future<void> init() async {
    _isBooting = true;
    notifyListeners();
    await _apiService.init();
    _currentUser = _apiService.currentUser;
    _isBooting = false;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    try {
      _setLoading(true);
      final data = await _apiService.login(identifier, password);
      _currentUser = User.fromJson(data['user']);
      _setLoading(false);
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.response?.data?['error'] ?? e.message ?? e.toString();
      }
      _setError(errorMsg);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String role,
    required String password,
    List<String>? jobTypes,
    String? location,
    int? experience,
  }) async {
    try {
      _setLoading(true);
      await _apiService.register(
        name: name,
        phone: phone,
        email: email,
        role: role,
        password: password,
        jobTypes: jobTypes,
        location: location,
        experience: experience,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.response?.data?['error'] ?? e.message ?? e.toString();
      }
      _setError(errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }
  
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? location,
    List<String>? skills,
    List<String>? jobTypes,
    int? experience,
    Uint8List? profilePicBytes,
    String? profilePicName,
  }) async {
    try {
      _setLoading(true);
      final formData = FormData();
      if (name != null) formData.fields.add(MapEntry('name', name));
      if (bio != null) formData.fields.add(MapEntry('bio', bio));
      if (location != null) formData.fields.add(MapEntry('location', location));
      if (experience != null) formData.fields.add(MapEntry('experience', experience.toString()));
      
      if (skills != null) {
        for (var skill in skills) {
          formData.fields.add(MapEntry('skills', skill));
        }
      }

      if (jobTypes != null) {
        for (var jt in jobTypes) {
          formData.fields.add(MapEntry('jobTypes', jt));
        }
      }

      if (profilePicBytes != null) {
        formData.files.add(MapEntry(
          'profilePic',
          MultipartFile.fromBytes(profilePicBytes, filename: profilePicName ?? 'profile.jpg'),
        ));
      }

      _currentUser = await _apiService.updateMe(formData);
      _setLoading(false);
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.response?.data?['error'] ?? e.message ?? e.toString();
      }
      _setError(errorMsg);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _isLoading = false;
    notifyListeners();
  }
}
