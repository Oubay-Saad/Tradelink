import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../post/portfolio_post_details_screen.dart';
import '../../utils/image_utils.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Post> _posts = [];
  Map<String, dynamic>? _reviewsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService().getUserProfile(widget.userId);
      User user = User.fromJson(data['user']);
      
      Map<String, dynamic>? reviews;
      if (user.role == 'tradesman') {
        try {
          reviews = await ApiService().getReviews(widget.userId);
        } catch (e) {
          print("Error fetching reviews: $e");
        }
      }

      setState(() {
        _user = user;
        if (data['posts'] != null) {
          _posts = (data['posts'] as List).map((e) => Post.fromJson(e)).toList();
        }
        _reviewsData = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text('User not found')));

    final isTradesman = _user!.role == 'tradesman';

    return DefaultTabController(
      length: isTradesman ? 3 : 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text(_user!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileImage(),
                    const SizedBox(height: 16),
                    Text(_user!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _user!.location ?? 'No location',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    if (isTradesman)
                      TabBar(
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF2563EB),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Gallery'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                  ],
                ),
              ),
            ];
          },
          body: isTradesman 
            ? TabBarView(
                children: [
                  _buildAboutTab(),
                  _buildGalleryTab(),
                  _buildReviewsTab(),
                ],
              )
            : _buildAboutTab(), // Customers only have About
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ImageUtils.buildCircleAvatar(
      imageUrl: _user!.profilePic,
      radius: 50,
      fallbackIcon: Icons.person,
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone, 'Phone', _user!.phone),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, 'Email', _user!.email),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_user!.bio ?? 'No bio available.', style: TextStyle(color: Colors.grey[700], height: 1.5)),
          const SizedBox(height: 24),
          
          if (_user!.role == 'tradesman' && _user!.tradesmanInfo != null) ...[
            _buildInfoRow(Icons.work_outline, 'Experience', '${_user!.tradesmanInfo!.experience} Years'),
            const SizedBox(height: 16),
            const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.tradesmanInfo!.skills.map((s) => Chip(
                label: Text(s),
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.05),
                labelStyle: const TextStyle(color: Color(0xFF2563EB), fontSize: 12),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    if (_posts.isEmpty) {
      return const Center(child: Text('No work gallery yet.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PortfolioPostDetailsScreen(postId: post.id),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: post.images.isNotEmpty 
                    ? _buildPostThumbnail(post.images.first)
                    : const Icon(Icons.image_not_supported),
                ),
                if (post.images.length > 1)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.collections_rounded,
                      color: Colors.white,
                      size: 20,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostThumbnail(String img) {
    final isUrl = img.startsWith('http');
    final isBase64 = img.startsWith('data:image') || (!isUrl && img.length > 50);
    if (isBase64 && !isUrl) {
      try {
        String b64 = img;
        if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
        b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
        while (b64.length % 4 != 0) b64 += '=';
        return Image.memory(base64Decode(b64), fit: BoxFit.cover);
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image));
      }
    }
    return Image.network(img, fit: BoxFit.cover);
  }

  void _showReviewDialog({String? reviewId, int? initialRating, String? initialComment}) {
    int selectedRating = initialRating ?? 5;
    final commentController = TextEditingController(text: initialComment);
    final isEditing = reviewId != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Review' : 'Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () {
                    setDialogState(() {
                      int newRating = index + 1;
                      if (newRating == 1 && selectedRating == 1) {
                        selectedRating = 0;
                      } else {
                        selectedRating = newRating;
                      }
                    });
                  },
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                )),
              ),
              const SizedBox(height: 8),
              Text(selectedRating == 0 ? '0 Stars (Poor)' : '$selectedRating Stars', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEditing) {
                    await ApiService().updateReview(
                      reviewId: reviewId,
                      rating: selectedRating,
                      comment: commentController.text,
                    );
                  } else {
                    await ApiService().createReview(
                      tradesmanId: widget.userId,
                      rating: selectedRating,
                      comment: commentController.text,
                    );
                  }
                  Navigator.pop(context);
                  _fetchProfile(); // Refresh
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviews = _reviewsData != null ? (_reviewsData!['reviews'] as List) : [];
    final avgRating = _reviewsData != null ? (_reviewsData!['averageRating']?.toString() ?? '0.0') : '0.0';
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isCustomer = currentUser?.role == 'customer';
    
    // Check if current user already has a review
    final hasAlreadyReviewed = reviews.any((r) => r['customer']?['_id'] == currentUser?.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isCustomer && !hasAlreadyReviewed)
                TextButton.icon(
                  onPressed: () => _showReviewDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Review'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(avgRating, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < double.parse(avgRating).floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    )),
                  ),
                  Text('${reviews.length} reviews', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (reviews.isEmpty)
            const Center(child: Text('No reviews yet.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final r = reviews[index];
                final customer = r['customer'];
                final customerId = customer?['_id'];
                final isOwner = currentUser?.id == customerId;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (customerId != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => UserProfileScreen(userId: customerId),
                              ));
                            }
                          },
                          child: Builder(
                            builder: (context) {
                              final pic = customer?['profilePic'];
                              if (pic == null || pic.isEmpty) {
                                return CircleAvatar(
                                  radius: 16, 
                                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  child: Text(customer?['name']?[0] ?? '?', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)))
                                );
                              }
                              final isUrl = pic.startsWith('http');
                              final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                              if (isBase64 && !isUrl) {
                                try {
                                  String b64 = pic;
                                  if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
                                  b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
                                  while (b64.length % 4 != 0) b64 += '=';
                                  return CircleAvatar(radius: 16, backgroundImage: MemoryImage(base64Decode(b64)));
                                } catch (_) {
                                  return const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16));
                                }
                              }
                              return CircleAvatar(radius: 16, backgroundImage: NetworkImage(pic));
                            }
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (customerId != null) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => UserProfileScreen(userId: customerId),
                                    ));
                                  }
                                },
                                child: Text(customer?['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              Row(
                                children: [
                                  Text(r['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isOwner) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                            onPressed: () => _showReviewDialog(
                              reviewId: r['_id'],
                              initialRating: r['rating'],
                              initialComment: r['comment'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteReview(r['_id']),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 42.0),
                      child: Text(r['comment'] ?? '', style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmDeleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService().deleteReview(reviewId);
                Navigator.pop(context);
                _fetchProfile();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

