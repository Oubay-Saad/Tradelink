import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/post_card.dart';
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
      appBar: AppBar(title: const Text('My Services')),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<DataProvider>().fetchMyServices(),
              child: dataProvider.myServices.isEmpty
                  ? const Center(child: Text('You have no services. Create one!'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dataProvider.myServices.length,
                      itemBuilder: (context, index) {
                        final service = dataProvider.myServices[index];
                        return ServiceCard(
                          title: service.title,
                          description: service.description,
                          imageUrl: service.images.isNotEmpty ? service.images.first : null,
                          budget: service.budget,
                          authorName: 'Me',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()))
              .then((_) => context.read<DataProvider>().fetchMyServices());
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Service'),
      ),
    );
  }
}
