import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../theme/app_theme.dart';
import '../profile/user_profile_screen.dart';
import '../post/portfolio_post_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _topTradesmen = [];
  List<Map<String, dynamic>> _nearbyTradesmen = [];
  List<Map<String, dynamic>> _jobTypes = [];
  String _selectedJobFilter = 'all';
  bool _loadingTop = true;
  bool _loadingNearby = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        context.read<DataProvider>().fetchAllPosts();
        _fetchJobTypes();
        _fetchTopTradesmen();
        _fetchNearbyTradesmen();
      }
    });
  }

  Future<void> _fetchJobTypes() async {
    try {
      final types = await ApiService().getJobTypes();
      if (mounted) setState(() => _jobTypes = types);
    } catch (_) {}
  }

  Future<void> _fetchTopTradesmen([String? jobType]) async {
    setState(() => _loadingTop = true);
    try {
      final data = await ApiService().getTopTradesmen(jobType: jobType);
      if (mounted) setState(() { _topTradesmen = data; _loadingTop = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTop = false);
    }
  }

  Future<void> _fetchNearbyTradesmen() async {
    try {
      final data = await ApiService().getNearbyTradesmen(limit: 10);
      if (mounted) setState(() { _nearbyTradesmen = data; _loadingNearby = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchTopTradesmen(_selectedJobFilter == 'all' ? null : _selectedJobFilter),
      _fetchNearbyTradesmen(),
      context.read<DataProvider>().fetchAllPosts(),
    ]);
  }

  String _capitalize(String s) {
    return s.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final dataProvider = context.watch<DataProvider>();
    final recentPosts = dataProvider.posts.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ImageUtils.buildCircleAvatar(imageUrl: user?.profilePic, radius: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                                Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(user?.location ?? 'Set location', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top tradesmen
                _buildSectionHeader(Icons.emoji_events_rounded, 'Top Tradesmen', AppTheme.star, trailing: 'Top 5'),
                const SizedBox(height: 12),

                // Job type filter chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip('All', 'all'),
                      ..._jobTypes.take(15).map((jt) => _buildFilterChip(jt['en'] as String, jt['value'] as String)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_loadingTop)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (_topTradesmen.isEmpty)
                  _buildEmptyState(Icons.star_border_rounded, 'No ranked tradesmen yet')
                else
                  ...List.generate(_topTradesmen.length, (i) => _buildTopTradesmanCard(_topTradesmen[i], i + 1)),

                const SizedBox(height: 28),

                // Nearby tradesmen
                _buildSectionHeader(Icons.near_me_rounded, 'In ${user?.location ?? "Your Area"}', AppTheme.accent),
                const SizedBox(height: 12),

                if (_loadingNearby)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (_nearbyTradesmen.isEmpty)
                  _buildNearbyEmptyState(user?.location)
                else
                  SizedBox(
                    height: 185,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyTradesmen.length,
                      itemBuilder: (context, index) => _buildNearbyCard(_nearbyTradesmen[index]),
                    ),
                  ),

                const SizedBox(height: 28),

                // Recent posts
                _buildSectionHeader(Icons.auto_awesome_rounded, 'Recent Posts', AppTheme.accent),
                const SizedBox(height: 12),

                if (dataProvider.isLoading && dataProvider.posts.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (recentPosts.isEmpty)
                  _buildEmptyState(Icons.photo_library_outlined, 'No posts yet')
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentPosts.length,
                    itemBuilder: (context, index) => _buildPostCard(recentPosts[index]),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widgets

  Widget _buildSectionHeader(IconData icon, String title, Color iconColor, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
          if (trailing != null) Text(trailing, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyEmptyState(String? location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
        child: Column(
          children: [
            Icon(Icons.location_off_rounded, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(
              location == null ? 'Set your location to discover nearby tradesmen' : 'No tradesmen found in your area yet',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedJobFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        )),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedJobFilter = value);
          _fetchTopTradesmen(value == 'all' ? null : value);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary,
        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildTopTradesmanCard(Map<String, dynamic> tradesman, int rank) {
    final name = tradesman['name'] ?? 'Tradesman';
    final profilePic = tradesman['profilePic'];
    final avgRating = (tradesman['avgRating'] as num?)?.toDouble() ?? 0;
    final totalReviews = tradesman['totalReviews'] ?? 0;
    final location = tradesman['location'] ?? '';
    final jobTypes = tradesman['tradesmanInfo']?['jobTypes'] as List? ?? [];
    final id = tradesman['_id'] ?? '';

    Color rankColor;
    switch (rank) {
      case 1: rankColor = const Color(0xFFf59e0b); break;
      case 2: rankColor = const Color(0xFF94a3b8); break;
      case 3: rankColor = const Color(0xFFcd7f32); break;
      default: rankColor = AppTheme.primary; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: id))),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.25), width: 1.5) : Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: rankColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Center(
                    child: rank <= 3
                        ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 18)
                        : Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                ImageUtils.buildCircleAvatar(imageUrl: profilePic, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (jobTypes.isNotEmpty) Text(_capitalize(jobTypes.first.toString()), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          if (location.isNotEmpty) ...[
                            Text(' · ', style: TextStyle(color: AppTheme.divider)),
                            Icon(Icons.location_on, size: 11, color: AppTheme.textMuted),
                            Flexible(child: Text(location, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: rankColor, size: 18),
                      const SizedBox(width: 3),
                      Text(avgRating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: rankColor)),
                    ]),
                    Text('$totalReviews reviews', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> tradesman) {
    final name = tradesman['name'] ?? 'Tradesman';
    final profilePic = tradesman['profilePic'];
    final avgRating = (tradesman['avgRating'] as num?)?.toDouble() ?? 0;
    final totalReviews = tradesman['totalReviews'] ?? 0;
    final jobTypes = tradesman['tradesmanInfo']?['jobTypes'] as List? ?? [];
    final id = tradesman['_id'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: id))),
      child: Container(
        width: 148,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageUtils.buildCircleAvatar(imageUrl: profilePic, radius: 30),
            const SizedBox(height: 10),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (jobTypes.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(_capitalize(jobTypes.first.toString()), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 10),
            if (totalReviews > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.star, size: 14),
                  const SizedBox(width: 3),
                  Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(' ($totalReviews)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              )
            else
              Text('New', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final dynamic postedBy = post.postedBy;
    String? pic;
    String posterName = 'Professional';
    if (postedBy is User) { pic = postedBy.profilePic; posterName = postedBy.name; }
    else if (postedBy is Map) { pic = postedBy['profilePic']; posterName = postedBy['name'] ?? 'Professional'; }

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ImageUtils.buildCircleAvatar(imageUrl: pic, radius: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(posterName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  if (post.description != null && post.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(post.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (post.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
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
                              String b64 = imageUrl;
                              if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
                              b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
                              while (b64.length % 4 != 0) b64 += '=';
                              return Image.memory(base64Decode(b64), fit: BoxFit.cover);
                            } catch (_) {
                              return Container(color: Colors.grey[100], child: const Icon(Icons.broken_image));
                            }
                          }
                          return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)));
                        },
                      ),
                    ),
                    if (post.images.length > 1)
                      Positioned(
                        top: 10, right: 10,
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
}
