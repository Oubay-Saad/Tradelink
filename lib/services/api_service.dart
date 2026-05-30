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
    
    if (token != null) {
      try {
        final res = await _dio.get('/auth/me');
        currentUser = User.fromJson(res.data['user']);
      } catch (e) {
        // If token is invalid or expired
        token = null;
        currentUser = null;
        await prefs.remove('token');
      }
    }
  }

  // Auth
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final res = await _dio.post('/auth/login', data: {'identifier': identifier, 'password': password});
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
    List<String>? jobTypes,
    String? location,
    int? experience,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'password': password,
      if (location != null) 'location': location,
      if (experience != null) 'experience': experience,
    };
    if (jobTypes != null && jobTypes.isNotEmpty) {
      data['jobTypes'] = jobTypes;
    }
    final res = await _dio.post('/auth/register', data: data);
    return res.data;
  }

  Future<List<Map<String, dynamic>>> getJobTypes() async {
    final res = await _dio.get('/job-types');
    final List data = res.data['jobTypes'] ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getWilayas() async {
    final res = await _dio.get('/wilayas');
    final List data = res.data['wilayas'] ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getTopTradesmen({String? jobType, int limit = 5}) async {
    final res = await _dio.get('/users/top-tradesmen', queryParameters: {
      if (jobType != null && jobType.isNotEmpty && jobType.toLowerCase() != 'all') 'jobType': jobType,
      'limit': limit.toString(),
    });
    final List data = res.data['topTradesmen'] ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getNearbyTradesmen({int limit = 10}) async {
    final res = await _dio.get('/users/nearby', queryParameters: {'limit': limit.toString()});
    final List data = res.data['nearbyTradesmen'] ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> logout() async {
    token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Users
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

  // Posts
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

  Future<Post> updatePost(String id, FormData data) async {
    final res = await _dio.patch('/posts/$id', data: data);
    return Post.fromJson(res.data['post']);
  }

  Future<Post> deletePostImage(String id, int index) async {
    final res = await _dio.delete('/posts/$id/images/$index');
    return Post.fromJson(res.data['post']);
  }

  // Services
  Future<ServiceItem> createService(FormData data) async {
    final res = await _dio.post('/services', data: data);
    return ServiceItem.fromJson(res.data['service']);
  }

  Future<List<ServiceItem>> getServices({String? jobTypes, String? location, String? timeUploaded}) async {
    final res = await _dio.get('/services', queryParameters: {
      if (jobTypes != null && jobTypes.isNotEmpty) 'jobTypes': jobTypes,
      if (location != null && location.isNotEmpty) 'location': location,
      if (timeUploaded != null && timeUploaded.isNotEmpty) 'timeUploaded': timeUploaded,
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

  Future<void> editService(String id, dynamic data) async {
    await _dio.patch('/services/$id', data: data);
  }

  Future<void> deleteServiceImage(String id, int index) async {
    await _dio.delete('/services/$id/images/$index');
  }

  Future<List<Post>> getAllPosts({String? name}) async {
    final res = await _dio.get('/posts', queryParameters: {
      if (name != null && name.isNotEmpty) 'name': name,
    });
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

  Future<List<User>> searchTradesmen({String? name, String? location, String? jobType, int? experience, String? role}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (name != null && name.isNotEmpty) queryParameters['name'] = name;
      if (location != null && location.isNotEmpty) queryParameters['location'] = location;
      if (jobType != null && jobType.isNotEmpty && jobType.toLowerCase() != 'all') queryParameters['jobType'] = jobType;
      if (experience != null && experience > 0) queryParameters['experience'] = experience.toString();
      if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') queryParameters['role'] = role;

      final res = await _dio.get('/users/search', queryParameters: queryParameters);
      final List data = res.data['results'];
      return data.map((e) => User.fromJson(e)).toList();
    } on DioException catch (e) {
      print('Search Error: ${e.response?.data}');
      return [];
    }
  }

  Future<Map<String, dynamic>> getReviews(String tradesmanId) async {
    final res = await _dio.get('/review/$tradesmanId');
    return res.data;
  }

  Future<void> createReview({required String tradesmanId, required int rating, required String comment}) async {
    await _dio.post('/review/$tradesmanId', data: {
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> updateReview({required String reviewId, required int rating, required String comment}) async {
    await _dio.patch('/review/$reviewId', data: {
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio.delete('/review/$reviewId');
  }
}

