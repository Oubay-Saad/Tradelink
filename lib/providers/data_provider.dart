import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ServiceItem> _services = [];
  List<User> _users = [];
  bool _isLoading = false;
  bool _isRequestsLoading = false;

  List<ServiceItem> get services => _services;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isRequestsLoading => _isRequestsLoading;

  Future<void> fetchServices({String? jobType}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _services = await _apiService.getServices(jobType: jobType);
    } catch (e) {
      print("Error fetching services: \$e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchTradesmen({String? name, String? jobType}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _apiService.searchUsers(name: name, jobType: jobType, role: 'tradesman');
    } catch (e) {
      print("Error searching users: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Post> _posts = [];
  List<ServiceItem> _myServices = [];
  List<dynamic> _sentRequests = [];

  List<Post> get posts => _posts;
  List<ServiceItem> get myServices => _myServices;
  List<dynamic> get sentRequests => _sentRequests;

  Future<void> fetchAllPosts({String? name}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _posts = await _apiService.getAllPosts(name: name);
    } catch (e) {
      print("Error fetching posts: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyServices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myServices = await _apiService.getMyServices();
    } catch (e) {
      print("Error fetching my services: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSentRequests() async {
    _isRequestsLoading = true;
    notifyListeners();
    try {
      _sentRequests = await _apiService.getSentRequests();
      print("DataProvider: Fetched ${_sentRequests.length} sent requests");
    } catch (e) {
      print("Error fetching sent requests: $e");
    }
    _isRequestsLoading = false;
    notifyListeners();
  }
}
