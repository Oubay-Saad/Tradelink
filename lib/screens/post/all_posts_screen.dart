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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchAllPosts();
    });
  }

  void _search() {
    context.read<DataProvider>().fetchAllPosts(name: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final isTradesman = context.watch<AuthProvider>().currentUser?.role == 'tradesman';

    return Scaffold(
      appBar: AppBar(title: const Text('Community Posts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: dataProvider.isLoading && dataProvider.posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<DataProvider>().fetchAllPosts(name: _searchController.text),
                    child: dataProvider.posts.isEmpty
                        ? const Center(child: Text('No posts found.'))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: dataProvider.posts.length,
                      itemBuilder: (context, index) {
                        final post = dataProvider.posts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                                            return const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14));
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
                                                radius: 12,
                                                backgroundImage: MemoryImage(base64Decode(b64)),
                                              );
                                            } catch (e) {
                                              return const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14));
                                            }
                                          }
                                          
                                          return CircleAvatar(
                                            radius: 12,
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
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Text Content
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      if (post.description != null && post.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(post.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                ),
                                // Image
                                if (post.images.isNotEmpty)
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Builder(
                                            builder: (context) {
                                              final imageUrl = post.images.first;
                                              final isUrl = imageUrl.startsWith('http');
                                              final isBase64 = imageUrl.startsWith('data:image') || (!isUrl && imageUrl.length > 50);
                                              
                                              if (isBase64 && !isUrl) {
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
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                                                  );
                                                } catch (e) {
                                                  return Container(color: Colors.grey[100], child: const Icon(Icons.broken_image));
                                                }
                                              }
                                              
                                              return Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
                                              );
                                            }
                                          ),
                                        ),
                                        if (post.images.length > 1)
                                          const Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Icon(
                                              Icons.collections_rounded,
                                              color: Colors.white,
                                              size: 24,
                                              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
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
