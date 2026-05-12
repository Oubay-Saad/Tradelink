import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../profile/user_profile_screen.dart';
import '../post/portfolio_post_details_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().searchTradesmen();
      context.read<DataProvider>().fetchAllPosts();
    });
  }

  void _search() {
    context.read<DataProvider>().searchTradesmen(name: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await dataProvider.searchTradesmen();
            await dataProvider.fetchAllPosts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tradesmen...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                
                // Tradesmen Horizontal List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Professionals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                if (dataProvider.isLoading && dataProvider.users.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (dataProvider.users.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No tradesmen found.'))
                else
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: dataProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = dataProvider.users[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)));
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final pic = user.profilePic;
                                      if (pic == null || pic.isEmpty) {
                                        return const Icon(Icons.person, size: 40, color: Colors.grey);
                                      }
                                      
                                      final isUrl = pic.startsWith('http');
                                      final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                                      final isHtml = pic.trim().startsWith('<');
                                      
                                      if (isBase64 && !isHtml && !isUrl) {
                                        try {
                                          String base64String = pic;
                                          if (base64String.contains(',')) {
                                            base64String = base64String.substring(base64String.indexOf(',') + 1);
                                          }
                                          base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                                          
                                          // Ensure correct padding
                                          while (base64String.length % 4 != 0) {
                                            base64String += '=';
                                          }

                                          return CircleAvatar(
                                            radius: 40,
                                            backgroundImage: MemoryImage(base64Decode(base64String)),
                                          );
                                        } catch (e) {
                                          return const Icon(Icons.person, size: 40, color: Colors.grey);
                                        }
                                      }
                                      
                                      return CircleAvatar(
                                        radius: 40,
                                        backgroundImage: NetworkImage(pic),
                                      );
                                    }
                                  ),
                                  const SizedBox(height: 8),
                                Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(user.tradesmanInfo?.jobTypes.isNotEmpty == true ? user.tradesmanInfo!.jobTypes.first : 'Pro', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Random Posts Vertical List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Recent Portfolio Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                if (dataProvider.isLoading && dataProvider.posts.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (dataProvider.posts.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No posts found.'))
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dataProvider.posts.length,
                    itemBuilder: (context, index) {
                      final post = dataProvider.posts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                        );
                                      } catch (e) {
                                        return Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.broken_image));
                                      }
                                    }
                                    
                                    if (isHtml) return Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.broken_image));
                                    
                                    return Image.network(
                                      imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                                    );
                                  }
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (post.description != null)
                                      Text(post.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
                                    const SizedBox(height: 12),
                                    Row(
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
                                              return const CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Color(0xFF2563EB),
                                                child: Icon(Icons.person, size: 16, color: Colors.white),
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
                                                  radius: 14,
                                                  backgroundImage: MemoryImage(base64Decode(b64)),
                                                );
                                              } catch (e) {
                                                return const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16));
                                              }
                                            }
                                            
                                            return CircleAvatar(
                                              radius: 14,
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
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

