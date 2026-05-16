import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../../widgets/post_card.dart';
import '../../theme/app_theme.dart';
import '../post/post_details_screen.dart';
import '../profile/user_profile_screen.dart';
import '../../services/api_service.dart';

class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({super.key});

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchServices();
      context.read<DataProvider>().fetchSentRequests();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) context.read<DataProvider>().fetchSentRequests();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Services'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'My Applications'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Available Tab ──
          dataProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => context.read<DataProvider>().fetchServices(),
                  child: dataProvider.services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_off_rounded, size: 56, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              const Text('No services available', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: dataProvider.services.length,
                          itemBuilder: (context, index) {
                            final service = dataProvider.services[index];
                            return ServiceCard(
                              title: service.title,
                              description: service.description,
                              imageUrl: (service.images.isNotEmpty && service.images.first.isNotEmpty) ? service.images.first : null,
                              budget: service.budget,
                              authorName: service.createdBy is User ? (service.createdBy as User).name : (service.createdBy is Map ? service.createdBy['name'] ?? 'Unknown' : 'Customer'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsScreen(serviceId: service.id))),
                              onProfileTap: () {
                                final userId = service.createdBy is User
                                    ? (service.createdBy as User).id
                                    : (service.createdBy is Map ? service.createdBy['_id'] : service.createdBy?.toString());
                                if (userId != null && userId.toString().isNotEmpty) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId.toString())));
                                }
                              },
                            );
                          },
                        ),
                ),

          // ── My Applications Tab ──
          dataProvider.isRequestsLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => context.read<DataProvider>().fetchSentRequests(),
                  child: dataProvider.sentRequests.isEmpty
                      ? ListView(children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 56, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  const Text("No applications yet", style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text("Apply to services from the Available tab", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: dataProvider.sentRequests.length,
                          itemBuilder: (context, index) => _buildApplicationCard(dataProvider.sentRequests[index]),
                        ),
                ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(dynamic req) {
    final service = req['service'];
    final status = req['status'] ?? 'Pending';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Accepted': statusColor = AppTheme.success; statusIcon = Icons.check_circle_rounded; break;
      case 'Rejected': statusColor = AppTheme.error; statusIcon = Icons.cancel_rounded; break;
      default: statusColor = AppTheme.warning; statusIcon = Icons.schedule_rounded; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () {
          if (service == null) {
            _showDeletedServiceDialog(req);
            return;
          }
          final serviceId = service is Map ? service['_id'] : service?.toString() ?? 'deleted';
          Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsScreen(serviceId: serviceId, requestId: req['_id'])));
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service?['title'] ?? 'Service Deleted',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: service == null ? AppTheme.textMuted : AppTheme.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
              if (service == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('The owner has removed this service.', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text('My Price: \$${req['estimatedPrice']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('"${req['message']}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic))),
                ],
              ),
              if (status == 'Accepted' && service != null && service['createdBy'] != null && service['createdBy']['phone'] != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final phone = service['createdBy']['phone']?.toString() ?? '';
                      if (phone.isEmpty) return;
                      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('Call Customer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: BorderSide(color: AppTheme.success),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeletedServiceDialog(dynamic req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Service Unavailable', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This service has been deleted by the owner. Your request will be removed.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteRequest(req['_id']);
                if (context.mounted) {
                  context.read<DataProvider>().fetchSentRequests();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request removed.')));
                }
              } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error removing request.')));
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
