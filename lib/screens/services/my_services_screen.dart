import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/post_card.dart';
import '../../theme/app_theme.dart';
import '../post/post_details_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/user_profile_screen.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchMyServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Services'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                    .then((_) => context.read<DataProvider>().fetchMyServices());
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
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => context.read<DataProvider>().fetchMyServices(),
              child: dataProvider.myServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_business_rounded, size: 48, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text('No services yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          const SizedBox(height: 6),
                          const Text('Create your first service request!', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
                                  .then((_) => context.read<DataProvider>().fetchMyServices());
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Service'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: dataProvider.myServices.length,
                      itemBuilder: (context, index) {
                        final service = dataProvider.myServices[index];
                        return ServiceCard(
                          title: service.title,
                          description: service.description,
                          imageUrl: service.images.isNotEmpty ? service.images.first : null,
                          budget: service.budget,
                          authorName: 'Me',
                          location: service.location,
                          jobTypes: service.jobTypes,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PostDetailsScreen(serviceId: service.id),
                            ));
                          },
                          onProfileTap: () {
                            final userId = context.read<AuthProvider>().currentUser?.id;
                            if (userId != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
