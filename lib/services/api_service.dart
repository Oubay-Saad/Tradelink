import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/service.dart';

const String kBaseUrl = 'http://localhost:3000'; // Android emulator to localhost. Change to localhost or physical IP if needed.

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? token;
  User? currentUser;
  
  late final Dio _dio;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    
    // Optionally fetch user profile if token exists
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await _dio.post('/auth/login', data: {'phone': phone, 'password': password});
    token = res.data['token'];
    currentUser = User.fromJson(res.data['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token!);
    return res.data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String role,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'password': password,
    });
    return res.data;
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // --- Users ---
  Future<List<User>> searchUsers({String? name, String? role, String? jobType}) async {
    final res = await _dio.get('/users/search', queryParameters: {
      if (name != null && name.isNotEmpty) 'name': name,
      if (role != null && role.isNotEmpty) 'role': role,
      if (jobType != null && jobType.isNotEmpty) 'jobType': jobType,
    });
    return (res.data['results'] as List).map((e) => User.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final res = await _dio.get('/users/$userId');
    return res.data; // Includes user, posts or services based on role
  }

  Future<User> updateMe(FormData data) async {
    final res = await _dio.patch('/users/me', data: data);
    currentUser = User.fromJson(res.data['user']);
    return currentUser!;
  }

  // --- Posts ---
  Future<Post> createPost(FormData data) async {
    final res = await _dio.post('/posts', data: data);
    return Post.fromJson(res.data['post']);
  }

  Future<Post> getPost(String id) async {
    final res = await _dio.get('/posts/$id');
    return Post.fromJson(res.data['post']);
  }

  Future<void> deletePost(String id) async {
    await _dio.delete('/posts/$id');
  }

  // --- Services ---
  Future<ServiceItem> createService(FormData data) async {
    final res = await _dio.post('/services', data: data);
    return ServiceItem.fromJson(res.data['service']);
  }

  Future<List<ServiceItem>> getServices({String? jobType}) async {
    final res = await _dio.get('/services', queryParameters: {
      if (jobType != null && jobType.isNotEmpty) 'jobType': jobType,
    });
    return (res.data['services'] as List).map((e) => ServiceItem.fromJson(e)).toList();
  }

  Future<ServiceItem> getService(String id) async {
    final res = await _dio.get('/services/$id');
    return ServiceItem.fromJson(res.data['service']);
  }

  Future<void> deleteService(String id) async {
    await _dio.delete('/services/$id');
  }

  Future<List<Post>> getAllPosts() async {
    final res = await _dio.get('/posts');
    return (res.data['posts'] as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<ServiceItem>> getMyServices() async {
    if (currentUser == null) return [];
    final profile = await getUserProfile(currentUser!.id);
    if (profile['services'] != null) {
      return (profile['services'] as List).map((e) => ServiceItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createRequest({required String serviceId, required double estimatedPrice, required String message}) async {
    final res = await _dio.post('/services/$serviceId/requests', data: {'estimatedPrice': estimatedPrice, 'message': message});
    return res.data;
  }

  Future<List<dynamic>> getRequests(String serviceId) async {
    final res = await _dio.get('/services/$serviceId/requests');
    return res.data['requests'] ?? [];
  }

  Future<Map<String, dynamic>> updateRequestStatus(String requestId, String status) async {
    final res = await _dio.patch('/requests/$requestId/status', data: {'status': status});
    return res.data;
  }

  Future<List<dynamic>> getSentRequests() async {
    final res = await _dio.get('/requests/me');
    return res.data['requests'] ?? [];
  }

  Future<Map<String, dynamic>> editRequest({required String requestId, double? estimatedPrice, String? message}) async {
    final res = await _dio.patch('/requests/$requestId', data: {
      if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
      if (message != null) 'message': message,
    });
    return res.data;
  }

  Future<void> deleteRequest(String requestId) async {
    await _dio.delete('/requests/$requestId');
  }
}

