import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../profile/user_profile_screen.dart';
import 'portfolio_post_details_screen.dart';
import 'create_post_screen.dart';


class AllPostsScreen extends StatefulWidget {
  const AllPostsScreen({super.key});

  @override
  State<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchAllPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final isTradesman = context.watch<AuthProvider>().currentUser?.role == 'tradesman';

    return Scaffold(
      appBar: AppBar(title: const Text('Community Posts')),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<DataProvider>().fetchAllPosts(),
              child: dataProvider.posts.isEmpty
                  ? const Center(child: Text('No posts yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dataProvider.posts.length,
                      itemBuilder: (context, index) {
                        final post = dataProvider.posts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PortfolioPostDetailsScreen(postId: post.id),
                              ));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final dynamic postedBy = post.postedBy;
                                          String? pic;
                                          if (postedBy is User) {
                                            pic = postedBy.profilePic;
                                          } else if (postedBy is Map) {
                                            pic = postedBy['profilePic'];
                                          }

                                          if (pic == null || pic.isEmpty) {
                                            return CircleAvatar(
                                              radius: 16,
                                              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                              child: const Icon(Icons.person, size: 16, color: Color(0xFF2563EB)),
                                            );
                                          }
                                          
                                          final isUrl = pic.startsWith('http');
                                          final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                                          final isHtml = pic.trim().startsWith('<');
                                          
                                          if (isBase64 && !isHtml && !isUrl) {
                                            try {
                                              String b64 = pic;
                                              if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
                                              b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
                                              while (b64.length % 4 != 0) b64 += '=';
                                              return CircleAvatar(
                                                radius: 16,
                                                backgroundImage: MemoryImage(base64Decode(b64)),
                                              );
                                            } catch (e) {
                                              return const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16));
                                            }
                                          }
                                          
                                          return CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage(pic),
                                          );
                                        }
                                      ),
                                      const SizedBox(width: 8),
                                      Builder(
                                        builder: (context) {
                                          final dynamic postedBy = post.postedBy;
                                          String name = 'Professional';
                                          if (postedBy is User) {
                                            name = postedBy.name;
                                          } else if (postedBy is Map) {
                                            name = postedBy['name'] ?? 'Professional';
                                          }
                                          return Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (post.images.isNotEmpty)
                                  Builder(
                                    builder: (context) {
                                      final imageUrl = post.images.first;
                                      final isUrl = imageUrl.startsWith('http');
                                      final isBase64 = imageUrl.startsWith('data:image') || (!isUrl && imageUrl.length > 50);
                                      final isHtml = imageUrl.trim().startsWith('<');
                                      
                                      if (isBase64 && !isHtml && !isUrl) {
                                        try {
                                          String base64String = imageUrl;
                                          if (base64String.contains(',')) {
                                            base64String = base64String.substring(base64String.indexOf(',') + 1);
                                          }
                                          base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                                          
                                          while (base64String.length % 4 != 0) {
                                            base64String += '=';
                                          }

                                          return Image.memory(
                                            base64Decode(base64String),
                                            height: 250,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                          );
                                        } catch (e) {
                                          return Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.broken_image));
                                        }
                                      }
                                      
                                      if (isHtml) return Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.broken_image));
                                      
                                      return Image.network(
                                        imageUrl,
                                        height: 250,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                      );
                                    }
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      if (post.description != null && post.description!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(post.description!, style: TextStyle(color: Colors.grey[800], height: 1.4)),
                                      ]
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: isTradesman
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                    .then((_) => context.read<DataProvider>().fetchAllPosts());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            )
          : null,
    );
  }
}
