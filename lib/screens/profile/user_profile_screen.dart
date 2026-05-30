import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
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
        try { reviews = await ApiService().getReviews(widget.userId); } catch (_) {}
      }

      setState(() {
        _user = user;
        if (data['posts'] != null) _posts = (data['posts'] as List).map((e) => Post.fromJson(e)).toList();
        _reviewsData = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: Text('User not found')));

    final isTradesman = _user!.role == 'tradesman';

    return DefaultTabController(
      length: isTradesman ? 3 : 1,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
                          child: Column(
                            children: [
                              // Back button row
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const Spacer(),
                                  Text(_user!.role == 'tradesman' ? 'Tradesman' : 'Customer', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                                  const Spacer(),
                                  const SizedBox(width: 48),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 3)),
                                child: ImageUtils.buildCircleAvatar(imageUrl: _user!.profilePic, radius: 44),
                              ),
                              const SizedBox(height: 12),
                              Text(_user!.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              if (_user!.location != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.6)),
                                    const SizedBox(width: 4),
                                    Text(_user!.location!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Call button
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final phone = _user!.phone ?? '';
                                  if (phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number')));
                                    return;
                                  }
                                  final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri);
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
                                  }
                                },
                                icon: const Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                                label: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab bar
                    if (isTradesman)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textSecondary,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: const [Tab(text: 'About'), Tab(text: 'Gallery'), Tab(text: 'Reviews')],
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ];
          },
          body: isTradesman
              ? TabBarView(children: [_buildAboutTab(), _buildGalleryTab(), _buildReviewsTab()])
              : _buildAboutTab(),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact info card
          _buildCard(
            'Contact',
            Icons.contacts_rounded,
            children: [
              _buildInfoRow(Icons.phone_rounded, 'Phone', _user!.phone, showCopy: true),
              const Divider(height: 20, indent: 42),
              _buildInfoRow(Icons.email_rounded, 'Email', _user!.email, showCopy: true),
            ],
          ),
          const SizedBox(height: 14),

          // Bio
          if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
            _buildCard('About', Icons.info_outline_rounded, children: [
              Text(_user!.bio!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14)),
            ]),
            const SizedBox(height: 14),
          ],

          // Tradesman specifics
          if (_user!.role == 'tradesman' && _user!.tradesmanInfo != null) ...[
            if (_user!.tradesmanInfo!.jobTypes.isNotEmpty) ...[
              _buildCard('Specializations', Icons.build_rounded, children: [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _user!.tradesmanInfo!.jobTypes.map((jt) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      jt.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  )).toList(),
                ),
              ]),
              const SizedBox(height: 14),
            ],

            _buildCard('Experience & Skills', Icons.timeline_rounded, children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.work_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('${_user!.tradesmanInfo!.experience ?? 0} Years Experience', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              if (_user!.tradesmanInfo!.skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _user!.tradesmanInfo!.skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text(s, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12)),
                  )).toList(),
                ),
              ],
            ]),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool showCopy = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppTheme.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
        if (showCopy && value.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
            },
          ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('No work gallery yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 4 / 3),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PortfolioPostDetailsScreen(postId: post.id))),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              color: AppTheme.background,
              border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: post.images.isNotEmpty ? _buildPostThumbnail(post.images.first) : const Icon(Icons.image_not_supported_rounded, color: AppTheme.textMuted)),
                // Title overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                    ),
                    child: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (post.images.length > 1)
                  Positioned(top: 6, right: 6, child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.collections_rounded, color: Colors.white, size: 14),
                  )),
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
      } catch (_) { return const Center(child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted)); }
    }
    return Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted)));
  }

  void _showReviewDialog({String? reviewId, int? initialRating, String? initialComment}) {
    int selectedRating = initialRating ?? 5;
    final commentController = TextEditingController(text: initialComment);
    final isEditing = reviewId != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Text(isEditing ? 'Edit Review' : 'Add Review', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  onPressed: () {
                    setDialogState(() {
                      int newRating = index + 1;
                      selectedRating = (newRating == 1 && selectedRating == 1) ? 0 : newRating;
                    });
                  },
                  icon: Icon(index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded, color: AppTheme.star, size: 32),
                )),
              ),
              const SizedBox(height: 4),
              Text(selectedRating == 0 ? '0 Stars' : '$selectedRating Stars', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(hintText: 'Share your experience...'),
                maxLines: 3,
                maxLength: 250,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEditing) {
                    await ApiService().updateReview(reviewId: reviewId, rating: selectedRating, comment: commentController.text);
                  } else {
                    await ApiService().createReview(tradesmanId: widget.userId, rating: selectedRating, comment: commentController.text);
                  }
                  Navigator.pop(context);
                  _fetchProfile();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final hasAlreadyReviewed = reviews.any((r) => r['customer']?['_id'] == currentUser?.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Text(avgRating, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: List.generate(5, (i) => Icon(i < double.parse(avgRating).floor() ? Icons.star_rounded : Icons.star_outline_rounded, color: AppTheme.star, size: 20))),
                      const SizedBox(height: 4),
                      Text('${reviews.length} reviews', style: const TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (isCustomer && !hasAlreadyReviewed)
                  ElevatedButton(
                    onPressed: () => _showReviewDialog(),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    child: const Text('Add', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  const Text('No reviews yet', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          else
            ...reviews.map((r) => _buildReviewItem(r, currentUser)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(dynamic r, User? currentUser) {
    final customer = r['customer'];
    final customerId = customer?['_id'];
    final isOwner = currentUser?.id == customerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: customerId != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: customerId))) : null,
                child: ImageUtils.buildCircleAvatar(imageUrl: customer?['profilePic'], radius: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: customerId != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: customerId))) : null,
                      child: Text(customer?['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Row(children: [
                      ...List.generate(5, (i) => Icon(i < (r['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: AppTheme.star, size: 14)),
                    ]),
                  ],
                ),
              ),
              if (isOwner) ...[
                IconButton(icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.textMuted), onPressed: () => _showReviewDialog(reviewId: r['_id'], initialRating: r['rating'], initialComment: r['comment'])),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error), onPressed: () => _confirmDeleteReview(r['_id'])),
              ],
            ],
          ),
          if (r['comment'] != null && r['comment'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 8),
              child: Text(r['comment'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Delete Review', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService().deleteReview(reviewId);
                Navigator.pop(context);
                _fetchProfile();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
