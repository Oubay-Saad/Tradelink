import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../profile/user_profile_screen.dart';

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

    if (_post == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }

    final postedBy = _post!.postedBy is User ? _post!.postedBy as User : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Work Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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

                        if (pic == null || pic.isEmpty) {
                          return const CircleAvatar(radius: 24, child: Icon(Icons.person));
                        }
                        
                        final isUrl = pic.startsWith('http');
                        final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                        
                        if (isBase64 && !isUrl) {
                          try {
                            String b64 = pic;
                            if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
                            b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
                            while (b64.length % 4 != 0) b64 += '=';
                            return CircleAvatar(
                              radius: 24,
                              backgroundImage: MemoryImage(base64Decode(b64)),
                            );
                          } catch (e) {
                            return const CircleAvatar(radius: 24, child: Icon(Icons.person));
                          }
                        }
                        return CircleAvatar(radius: 24, backgroundImage: NetworkImage(pic));
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
