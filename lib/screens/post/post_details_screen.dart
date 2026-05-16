import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../models/service.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../profile/user_profile_screen.dart';
import '../services/edit_service_screen.dart';
import '../../theme/app_theme.dart';

class PostDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String? requestId;

  const PostDetailsScreen({super.key, required this.serviceId, this.requestId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  ServiceItem? _service;
  List<dynamic> _requests = [];
  bool _isLoading = true;
  bool _isDeleted = false;
  dynamic _deletedRequestData;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final Map<int, Uint8List> _decodedImages = {};

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() async {
    try {
      final svc = await ApiService().getService(widget.serviceId);
      final reqs = await ApiService().getRequests(widget.serviceId);

      // Pre-decode images to prevent lag
      if (svc.images.isNotEmpty) {
        for (int i = 0; i < svc.images.length; i++) {
          final imageUrl = svc.images[i];
          final isUrl = imageUrl.startsWith('http');
          final isBase64 = imageUrl.startsWith('data:image') || (!isUrl && imageUrl.length > 50);
          final isHtml = imageUrl.trim().startsWith('<');

          if (isBase64 && !isHtml && !isUrl) {
            try {
              String b64 = imageUrl;
              if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
              b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
              while (b64.length % 4 != 0) b64 += '=';
              _decodedImages[i] = base64Decode(b64);
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() {
          _service = svc;
          _requests = reqs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 404 && widget.requestId != null) {
          final dataProvider = context.read<DataProvider>();
          final req = dataProvider.sentRequests.firstWhere(
            (r) => r['_id'] == widget.requestId,
            orElse: () => null,
          );
          
          setState(() {
            _isDeleted = true;
            _deletedRequestData = req;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _updateRequestStatus(String reqId, String status) async {
    try {
      await ApiService().updateRequestStatus(reqId, status);
      _fetchDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Details')), body: const Center(child: CircularProgressIndicator()));
    }

    if (_isDeleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Removed')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'This service has been deleted',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'The customer has removed this service from the platform. Your application is no longer active.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_deletedRequestData != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('My Proposed Price: \$${_deletedRequestData['estimatedPrice']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Message: ${_deletedRequestData['message']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton.icon(
                onPressed: () => _confirmDeleteRequest(widget.requestId!),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Remove from My Applications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(appBar: AppBar(title: const Text('Details')), body: const Center(child: Text('Not found')));
    }

    final currentUser = context.watch<AuthProvider>().currentUser;
    final isTradesman = currentUser?.role == 'tradesman';
    final isOwner = _service!.createdBy is User 
        ? (_service!.createdBy as User).id == currentUser?.id 
        : _service!.createdBy.toString() == currentUser?.id;

    final hasAcceptedRequest = _requests.any((r) => r['status'] == 'Accepted');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Service Details', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (isOwner && !isTradesman && _service != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditServiceScreen(service: _service!)),
                );
                if (result == true) {
                  _fetchDetails();
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(_service!.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                        child: Text('\$${_service!.budget}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      final userId = _service!.createdBy is User ? (_service!.createdBy as User).id : _service!.createdBy?.toString();
                      if (userId != null && userId.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
                      }
                    },
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final creator = _service!.createdBy is User ? _service!.createdBy as User : null;
                            final pic = creator?.profilePic;
                            if (pic == null || pic.isEmpty) return const CircleAvatar(radius: 20, child: Icon(Icons.person));
                            
                            final isUrl = pic.startsWith('http');
                            final isBase64 = pic.startsWith('data:image') || (!isUrl && pic.length > 50);
                            
                            if (isBase64 && !isUrl) {
                              try {
                                String b64 = pic;
                                if (b64.contains(',')) b64 = b64.substring(b64.indexOf(',') + 1);
                                b64 = b64.trim().replaceAll(RegExp(r'\s+'), '');
                                while (b64.length % 4 != 0) b64 += '=';
                                return CircleAvatar(radius: 20, backgroundImage: MemoryImage(base64Decode(b64)));
                              } catch (e) {
                                return const CircleAvatar(radius: 20, child: Icon(Icons.person));
                              }
                            }
                            return CircleAvatar(radius: 20, backgroundImage: NetworkImage(pic));
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _service!.createdBy is User ? (_service!.createdBy as User).name : 'Professional',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Image Gallery
            if (_service!.images.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 400,
                    color: Colors.black,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _service!.images.length,
                      onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                      itemBuilder: (context, index) {
                        if (_decodedImages.containsKey(index)) {
                          return Image.memory(_decodedImages[index]!, fit: BoxFit.contain, gaplessPlayback: true);
                        }
                        
                        final imageUrl = _service!.images[index];
                        final isUrl = imageUrl.startsWith('http');
                        final isHtml = imageUrl.trim().startsWith('<');

                        if (isHtml) return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 40));
                        return Image.network(imageUrl, fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 40)));
                      },
                    ),
                  ),
                  if (_service!.images.length > 1) ...[
                    Positioned(left: 8, child: Icon(Icons.chevron_left, color: Colors.white.withValues(alpha: 0.5), size: 30)),
                    Positioned(right: 8, child: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 30)),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_currentImageIndex + 1} / ${_service!.images.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_service!.description, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),
                  const SizedBox(height: 32),
                  
                  if (!isOwner && isTradesman) ...[
                    Builder(
                      builder: (context) {
                        final myRequest = _requests.firstWhere(
                          (r) {
                            final requesterId = r['requestedBy'] is Map 
                                ? r['requestedBy']['_id'] 
                                : r['requestedBy'].toString();
                            return requesterId == currentUser?.id;
                          },
                          orElse: () => null,
                        );

                        if (myRequest == null) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text('My Application', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('My Price: \$${myRequest['estimatedPrice']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: AppTheme.primary),
                                            onPressed: () => _showApplyDialog(context, existingRequest: myRequest),
                                            tooltip: 'Edit Application',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _confirmDeleteRequest(myRequest['_id']),
                                            tooltip: 'Withdraw Application',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(myRequest['message'] ?? 'No message provided', style: TextStyle(color: Colors.grey[800], height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  
                  if (isOwner) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_requests.isEmpty)
                      const Text('No requests yet.', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final reqStatus = req['status'] ?? 'Pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  onTap: () {
                                    final requestedBy = req['requestedBy'];
                                    final userId = requestedBy is Map ? requestedBy['_id'] : requestedBy?.toString();
                                    if (userId != null) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
                                    }
                                  },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Estimated: \$${req['estimatedPrice']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: reqStatus == 'Accepted' ? Colors.green.withValues(alpha: 0.1) : reqStatus == 'Rejected' ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(reqStatus.toUpperCase(), style: TextStyle(color: reqStatus == 'Accepted' ? Colors.green : reqStatus == 'Rejected' ? Colors.red : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(req['message'] ?? 'No message provided', style: TextStyle(color: Colors.grey[800], height: 1.4)),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          CircleAvatar(radius: 12, backgroundColor: AppTheme.primary.withOpacity(0.1), child: const Icon(Icons.person, size: 14, color: AppTheme.primary)),
                                          const SizedBox(width: 8),
                                          const Text('View professional\'s profile', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          const Icon(Icons.chevron_right, color: AppTheme.primary, size: 20),
                                        ],
                                      ),
                                      if (reqStatus == 'Pending' && !hasAcceptedRequest) ...[
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _updateRequestStatus(req['_id'], 'Rejected'),
                                                icon: const Icon(Icons.close, size: 18),
                                                label: const Text('Decline'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _updateRequestStatus(req['_id'], 'Accepted'),
                                                icon: const Icon(Icons.check, size: 18),
                                                label: const Text('Accept'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ] else if (reqStatus == 'Accepted' && req['requestedBy'] != null && req['requestedBy']['phone'] != null) ...[
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final phone = req['requestedBy']['phone']?.toString() ?? '';
                                              if (phone.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User does not have a phone number')));
                                                return;
                                              }
                                              final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                                              if (await canLaunchUrl(phoneUri)) {
                                                await launchUrl(phoneUri);
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.phone),
                                            label: const Text('Call Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            builder: (context) {
              final myRequest = _requests.firstWhere(
                (r) {
                  final requesterId = r['requestedBy'] is Map 
                      ? r['requestedBy']['_id'] 
                      : r['requestedBy'].toString();
                  return requesterId == currentUser?.id;
                },
                orElse: () => null,
              );

              if (isTradesman && !isOwner) {
                if (myRequest != null) {
                  final status = myRequest['status'];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: status == 'Accepted' ? Colors.green.withOpacity(0.1) : 
                                 status == 'Rejected' ? Colors.red.withOpacity(0.1) : 
                                 Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Application Status: $status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: status == 'Accepted' ? Colors.green : 
                                   status == 'Rejected' ? Colors.red : 
                                   Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (status == 'Accepted' && _service?.createdBy != null && _service!.createdBy!.phone != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final phone = _service!.createdBy!.phone ?? '';
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Owner does not have a phone number')));
                                return;
                              }
                              final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
                                }
                              }
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                if (hasAcceptedRequest) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Service no longer available',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return ElevatedButton(
                  onPressed: () => _showApplyDialog(context),
                  child: const Text('Apply for Service'),
                );
              }
              if (isOwner) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Service'),
                        content: const Text('Are you sure you want to delete this service? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await ApiService().deleteService(widget.serviceId);
                      if (mounted) {
                        context.read<DataProvider>().fetchServices();
                        context.read<DataProvider>().fetchMyServices();
                        Navigator.pop(context, true);
                      }
                    } catch(e) {
                      if (mounted) {
                        String errMsg = 'Delete failed';
                        if (e is DioException) {
                          errMsg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? e.message ?? 'Delete failed';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
                      }
                    }
                  },
                  child: const Text('Delete Service'),
                );
              }
              return const SizedBox.shrink();
            }
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRequest(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text('Are you sure you want to withdraw your application? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRequest(requestId);
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _deleteRequest(String requestId) async {
    try {
      await ApiService().deleteRequest(requestId);
      _fetchDetails();
      if (mounted) {
        context.read<DataProvider>().fetchSentRequests();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application withdrawn successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to withdraw application')));
      }
    }
  }

  void _showApplyDialog(BuildContext context, {dynamic existingRequest}) {
    final priceCtrl = TextEditingController(text: existingRequest != null ? existingRequest['estimatedPrice'].toString() : '');
    final msgCtrl = TextEditingController(text: existingRequest != null ? existingRequest['message'] : '');
    final isEditing = existingRequest != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Application' : 'Apply for Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Estimated Price (\$)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return TextField(
                    controller: msgCtrl,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: const OutlineInputBorder(),
                      counterText: '${msgCtrl.text.length}/100',
                      counterStyle: TextStyle(color: msgCtrl.text.length > 100 ? Colors.red : Colors.grey),
                    ),
                    maxLines: 3,
                    maxLength: 100,
                    onChanged: (val) => setDialogState(() {}),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              if (price == null || msgCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                return;
              }

              try {
                if (isEditing) {
                  await ApiService().editRequest(
                    requestId: existingRequest['_id'],
                    estimatedPrice: price,
                    message: msgCtrl.text,
                  );
                } else {
                  await ApiService().createRequest(
                    serviceId: widget.serviceId,
                    estimatedPrice: price,
                    message: msgCtrl.text,
                  );
                }

                Navigator.pop(ctx);
                _fetchDetails();
                if (mounted) {
                  context.read<DataProvider>().fetchSentRequests();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Application updated!' : 'Request sent successfully!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error submitting request')));
                }
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Submit'),
          ),
        ],
      ),
    );
  }
}
