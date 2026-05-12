import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ApiService().getUserProfile(widget.userId);
      setState(() {
        _user = User.fromJson(data['user']);
        if (data['posts'] != null) {
          _posts = (data['posts'] as List).map((e) => Post.fromJson(e)).toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text('User not found')));

    final isTradesman = _user!.role == 'tradesman';

    return Scaffold(
      appBar: AppBar(title: Text(_user!.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final pic = _user!.profilePic;
                if (pic == null || pic.isEmpty) {
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  );
                }
                
                final isUrl = pic.startsWith('http');
                final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                
                if (isBase64 && !isUrl) {
                  try {
                    String base64String = pic;
                    if (base64String.contains(',')) {
                      base64String = base64String.substring(base64String.indexOf(',') + 1);
                    }
                    base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                    
                    while (base64String.length % 4 != 0) {
                      base64String += '=';
                    }

                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: MemoryImage(base64Decode(base64String)),
                    );
                  } catch (e) {
                    return CircleAvatar(radius: 50, backgroundColor: Colors.grey[200], child: const Icon(Icons.person));
                  }
                }
                
                return CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(pic),
                );
              }
            ),
            const SizedBox(height: 16),
            Text(_user!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (_user!.bio != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(_user!.bio!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              ),
            ],
            const SizedBox(height: 16),
            if (isTradesman && _user!.tradesmanInfo != null) ...[
              Wrap(
                spacing: 8,
                children: _user!.tradesmanInfo!.jobTypes.map((j) => Chip(label: Text(j), backgroundColor: const Color(0xFF2563EB).withOpacity(0.1), labelStyle: const TextStyle(color: Color(0xFF2563EB)))).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Gallery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_posts.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No posts yet.'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    if (post.images.isEmpty) return Container(color: Colors.grey[200]);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Builder(
                        builder: (context) {
                          final img = post.images.first;
                          final isUrl = img.startsWith('http');
                          final isBase64 = img.startsWith('data:image') || (!isUrl && img.length > 50);
                          final isHtml = img.trim().startsWith('<');

                          if (isBase64 && !isHtml && !isUrl) {
                            try {
                              String base64String = img;
                              if (base64String.contains(',')) {
                                base64String = base64String.substring(base64String.indexOf(',') + 1);
                              }
                              base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                              
                              while (base64String.length % 4 != 0) {
                                base64String += '=';
                              }

                              return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
                            } catch (e) {
                              return Container(color: Colors.grey[200]);
                            }
                          }

                          if (isHtml) {
                            return Container(color: Colors.grey[200]);
                          }
                          return Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]));
                        }
                      ),
                    );
                  },
                )
            ]
          ],
        ),
      ),
    );
  }
}

