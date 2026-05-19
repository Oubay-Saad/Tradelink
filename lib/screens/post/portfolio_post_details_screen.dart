import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../profile/user_profile_screen.dart';
import 'edit_post_screen.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

import '../../utils/image_utils.dart';

class PortfolioPostDetailsScreen extends StatefulWidget {
  final String postId;

  const PortfolioPostDetailsScreen({super.key, required this.postId});

  @override
  State<PortfolioPostDetailsScreen> createState() => _PortfolioPostDetailsScreenState();
}

class _PortfolioPostDetailsScreenState extends State<PortfolioPostDetailsScreen> {
  Post? _post;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final Map<int, Uint8List> _decodedImages = {};

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final post = await ApiService().getPost(widget.postId);
      
      // Pre-decode images in background to prevent lag
      if (post.images.isNotEmpty) {
        for (int i = 0; i < post.images.length; i++) {
          final imageUrl = post.images[i];
          final isUrl = imageUrl.startsWith('http');
          final isBase64 = imageUrl.startsWith('data:image') || (!isUrl && imageUrl.length > 50);
          final isHtml = imageUrl.trim().startsWith('<');

          if (isBase64 && !isHtml && !isUrl) {
            try {
              String b64 = imageUrl;
              if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
              b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
              while (b64.length % 4 != 0) b64 += '=';
              _decodedImages[i] = base64Decode(b64);
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _editPost() {
    if (_post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(post: _post!)),
    ).then((updated) {
      if (updated == true) {
        setState(() {
          _isLoading = true;
          _decodedImages.clear();
        });
        _fetchPost();
      }
    });
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this portfolio post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ApiService().deletePost(widget.postId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully')));
                  Navigator.pop(context, true); // return true to refresh list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post: $e'), backgroundColor: AppTheme.error));
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(int index) {
    if (_decodedImages.containsKey(index)) {
      return Image.memory(
        _decodedImages[index]!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
      );
    }

    final imageUrl = _post!.images[index];
    final isUrl = imageUrl.startsWith('http');
    final isHtml = imageUrl.trim().startsWith('<');

    if (isHtml) return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50));

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUser = context.watch<AuthProvider>().currentUser;
    final dynamic creator = _post!.postedBy;
    final String? creatorId = creator is User ? creator.id : (creator is Map ? creator['_id'] : creator?.toString());
    final isOwner = currentUser != null && creatorId == currentUser.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Work Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _editPost();
                } else if (val == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppTheme.textPrimary, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Post'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: AppTheme.error, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Post', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final dynamic creator = _post!.postedBy;
                      final String? userId = creator is User ? creator.id : (creator is Map ? creator['_id'] : creator?.toString());
                      if (userId != null && userId.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final dynamic creator = _post!.postedBy;
                        String? pic;
                        if (creator is User) {
                          pic = creator.profilePic;
                        } else if (creator is Map) {
                          pic = creator['profilePic'];
                        }

                        return ImageUtils.buildCircleAvatar(imageUrl: pic, radius: 24);
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final dynamic creator = _post!.postedBy;
                            String name = 'Professional';
                            if (creator is User) {
                              name = creator.name;
                            } else if (creator is Map) {
                              name = creator['name'] ?? 'Professional';
                            }
                            return Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        Text(
                          'Portfolio Post',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Title & Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post!.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  if (_post!.description != null && _post!.description!.isNotEmpty)
                    Text(
                      _post!.description!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image Gallery
            if (_post!.images.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 450,
                    width: double.infinity,
                    color: Colors.black,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _post!.images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) => _buildImage(index),
                    ),
                  ),
                  
                  // Arrows
                  if (_post!.images.length > 1) ...[
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 30),
                        onPressed: () {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                    ),
                    Positioned(
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 30),
                        onPressed: () {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                    ),
                  ],

                  // Indicators
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${_post!.images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
