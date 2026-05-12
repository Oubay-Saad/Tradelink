import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user.dart';
import '../../widgets/post_card.dart';
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
    if (_tabController.index == 1) {
      context.read<DataProvider>().fetchSentRequests();
    }
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
      appBar: AppBar(
        title: const Text('Browse Services'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Applications'),
          ],
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
            // Available Services Tab
            dataProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<DataProvider>().fetchServices(),
                    child: dataProvider.services.isEmpty
                        ? const Center(child: Text('No services found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: dataProvider.services.length,
                            itemBuilder: (context, index) {
                              final service = dataProvider.services[index];
                              return ServiceCard(
                                title: service.title,
                                description: service.description,
                                imageUrl: (service.images.isNotEmpty && service.images.first.isNotEmpty) ? service.images.first : null,
                                budget: service.budget,
                                authorName: service.createdBy is User ? (service.createdBy as User).name : (service.createdBy is Map ? service.createdBy['name'] ?? 'Unknown' : 'Customer'),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => PostDetailsScreen(serviceId: service.id),
                                  ));
                                },
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

            // My Applications Tab
            dataProvider.isRequestsLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<DataProvider>().fetchSentRequests(),
                    child: dataProvider.sentRequests.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: const Center(child: Text('You haven\'t applied to any services yet.')),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: dataProvider.sentRequests.length,
                            itemBuilder: (context, index) {
                              final req = dataProvider.sentRequests[index];
                              final service = req['service'];
                              final status = req['status'] ?? 'Pending';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  onTap: () {
                                    if (service == null) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Service Unavailable'),
                                          content: const Text('This service has been deleted by the owner. Your request will be removed from your applications.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                try {
                                                  await ApiService().deleteRequest(req['_id']);
                                                  if (context.mounted) {
                                                    context.read<DataProvider>().fetchSentRequests();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Request removed.'))
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Error removing request.'))
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    final serviceId = service is Map 
                                        ? service['_id'] 
                                        : (service?.toString() ?? 'deleted');
                                    
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => PostDetailsScreen(
                                        serviceId: serviceId,
                                        requestId: req['_id'],
                                      ),
                                    ));
                                  },
                                  title: Text(
                                    service?['title'] ?? 'Service Deleted', 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: service == null ? Colors.grey : Colors.black
                                    )
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (service == null)
                                        const Text('The owner has removed this service.', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'My Price: \$${req['estimatedPrice']}', 
                                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 13)
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Message: ${req['message']}', 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'Accepted' ? Colors.green.withOpacity(0.1) : 
                                             status == 'Rejected' ? Colors.red.withOpacity(0.1) : 
                                             Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status, 
                                      style: TextStyle(
                                        color: status == 'Accepted' ? Colors.green : 
                                               status == 'Rejected' ? Colors.red : 
                                               Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      )
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      );
  }
}
