import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: false,
        actions: [
          if (isTradesman)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                      .then((_) => context.read<DataProvider>().fetchAllPosts());
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: dataProvider.isLoading && dataProvider.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => context.read<DataProvider>().fetchAllPosts(),
              child: dataProvider.posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 56, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          const Text('No posts yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                          if (isTradesman) ...[
                            const SizedBox(height: 4),
                            const Text('Be the first to share your work!', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: dataProvider.posts.length,
                      itemBuilder: (context, index) {
                        final post = dataProvider.posts[index];
                        return _buildPostCard(post);
                      },
                    ),
            ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final dynamic postedBy = post.postedBy;
    String? pic;
    String posterName = 'Professional';
    String? posterId;
    if (postedBy is User) { pic = postedBy.profilePic; posterName = postedBy.name; posterId = postedBy.id; }
    else if (postedBy is Map) { pic = postedBy['profilePic']; posterName = postedBy['name'] ?? 'Professional'; posterId = postedBy['_id']; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PortfolioPostDetailsScreen(postId: post.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: GestureDetector(
                onTap: posterId != null
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: posterId!)))
                    : null,
                child: Row(
                  children: [
                    ImageUtils.buildCircleAvatar(imageUrl: pic, radius: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(posterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (post.createdAt != null)
                            Text(_timeAgo(post.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title & Description ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  if (post.description != null && post.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(post.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                  ],
                ],
              ),
            ),

            if (post.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 4 / 3,
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
                              if (base64String.contains(',')) base64String = base64String.substring(base64String.indexOf(',') + 1);
                              base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');
                              while (base64String.length % 4 != 0) base64String += '=';
                              return Image.memory(base64Decode(base64String), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _brokenImage());
                            } catch (e) {
                              return _brokenImage();
                            }
                          }
                          return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _brokenImage());
                        },
                      ),
                    ),
                    if (post.images.length > 1)
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.collections_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('${post.images.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _brokenImage() => Container(color: AppTheme.background, child: const Center(child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 40)));

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
