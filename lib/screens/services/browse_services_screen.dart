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
import '../../providers/auth_provider.dart';

class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({super.key});

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _jobTypesFilter = 'all'; // 'all', 'mine', 'custom'
  List<String> _customJobTypes = [];
  String? _locationFilter;
  String _timeFilter = 'all'; // 'all', 'last_24h', 'last_week', 'last_month'
  List<Map<String, dynamic>> _allJobTypes = [];
  List<Map<String, dynamic>> _wilayas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadJobTypes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
      context.read<DataProvider>().fetchSentRequests();
    });
  }

  void _loadJobTypes() async {
    try {
      final types = await ApiService().getJobTypes();
      final wilayas = await ApiService().getWilayas();
      setState(() {
        _allJobTypes = types;
        _wilayas = wilayas;
      });
    } catch (_) {}
  }

  void _applyFilters() {
    final authProvider = context.read<AuthProvider>();
    String? jobTypesParam;

    if (_jobTypesFilter == 'mine') {
      final mine = authProvider.currentUser?.tradesmanInfo?.jobTypes ?? [];
      if (mine.isNotEmpty) {
        jobTypesParam = mine.join(',');
      }
    } else if (_jobTypesFilter == 'custom') {
      if (_customJobTypes.isNotEmpty) {
        jobTypesParam = _customJobTypes.join(',');
      }
    }

    context.read<DataProvider>().fetchServices(
      jobTypes: jobTypesParam,
      location: (_locationFilter != null && _locationFilter!.isNotEmpty) ? _locationFilter : null,
      timeUploaded: _timeFilter != 'all' ? _timeFilter : null,
    );
  }

  void _showJobTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        List<String> tempSelected = List.from(_customJobTypes);
        final searchController = TextEditingController();
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allJobTypes.where((jt) {
              final en = (jt['en'] ?? '').toString().toLowerCase();
              return en.contains(searchQuery.toLowerCase());
            }).toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Job Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _customJobTypes = tempSelected;
                                if (_customJobTypes.isNotEmpty) {
                                  _jobTypesFilter = 'custom';
                                } else {
                                  _jobTypesFilter = 'all';
                                }
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Done', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search job types...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) => setModalState(() => searchQuery = val),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final jt = filtered[index];
                            final value = jt['value'] as String;
                            final label = jt['en'] as String;
                            final isSelected = tempSelected.contains(value);
                            return CheckboxListTile(
                              title: Text(label),
                              value: isSelected,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    tempSelected.add(value);
                                  } else {
                                    tempSelected.remove(value);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final authProvider = context.read<AuthProvider>();
            final myJobTypes = authProvider.currentUser?.tradesmanInfo?.jobTypes ?? [];

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _jobTypesFilter = 'all';
                              _customJobTypes = [];
                              _locationFilter = null;
                              _timeFilter = 'all';
                            });
                          },
                          child: const Text('Clear All', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),


                    const Text('Job Types', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('All Job Types'),
                          value: 'all',
                          groupValue: _jobTypesFilter,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setModalState(() => _jobTypesFilter = val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        if (myJobTypes.isNotEmpty)
                          RadioListTile<String>(
                            title: Text('My Job Types (${myJobTypes.length})'),
                            value: 'mine',
                            groupValue: _jobTypesFilter,
                            activeColor: AppTheme.primary,
                            onChanged: (val) => setModalState(() => _jobTypesFilter = val!),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        RadioListTile<String>(
                          title: Text(_customJobTypes.isEmpty 
                              ? 'Select Specific Job Types...' 
                              : 'Selected Job Types (${_customJobTypes.length})'),
                          value: 'custom',
                          groupValue: _jobTypesFilter,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setModalState(() => _jobTypesFilter = val!);
                            _showJobTypePicker();
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                    if (_jobTypesFilter == 'custom' && _customJobTypes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _customJobTypes.map((jt) {
                          final label = _allJobTypes.firstWhere((j) => j['value'] == jt, orElse: () => {'en': jt})['en'] as String;
                          return Chip(
                            label: Text(label, style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.primary.withOpacity(0.06),
                            side: BorderSide(color: AppTheme.primary.withOpacity(0.15)),
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Location filter
                    const Text('Location (Wilaya)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _wilayas.any((w) => w['name'] == _locationFilter) ? _locationFilter : null,
                      decoration: const InputDecoration(
                        hintText: 'Select a wilaya',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ..._wilayas.map((w) => DropdownMenuItem<String>(
                          value: w['name'] as String,
                          child: Text('${w['code']} - ${w['name']}'),
                        )),
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          _locationFilter = v;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Time uploaded
                    const Text('Time Uploaded', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTimeChip('all', 'All time', setModalState),
                        _buildTimeChip('last_24h', 'Last 24 hours', setModalState),
                        _buildTimeChip('last_week', 'Last week', setModalState),
                        _buildTimeChip('last_month', 'Last month', setModalState),
                      ],
                    ),

                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeChip(String value, String label, StateSetter setModalState) {
    final isSelected = _timeFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _timeFilter = value);
        }
      },
    );
  }

  Widget _buildStickyFilterBar() {
    final isFiltered = _jobTypesFilter != 'all' || _locationFilter != null || _timeFilter != 'all';
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showFilterBottomSheet,
                icon: Icon(Icons.tune_rounded, size: 18, color: isFiltered ? AppTheme.primary : AppTheme.textSecondary),
                label: Text(
                  isFiltered ? 'Filters Active' : 'Filter',
                  style: TextStyle(
                    color: isFiltered ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isFiltered ? AppTheme.primary.withOpacity(0.5) : AppTheme.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [

                      if (_jobTypesFilter != 'all')
                        _buildFilterActiveChip(
                          _jobTypesFilter == 'mine' 
                              ? 'My Job Types' 
                              : '${_customJobTypes.length} Job Types',
                          onClear: () {
                            setState(() {
                              _jobTypesFilter = 'all';
                              _customJobTypes = [];
                            });
                            _applyFilters();
                          },
                        ),
                      

                      if (_locationFilter != null)
                        _buildFilterActiveChip(
                          _locationFilter!,
                          onClear: () {
                            setState(() {
                              _locationFilter = null;
                            });
                            _applyFilters();
                          },
                        ),
                      

                      if (_timeFilter != 'all')
                        _buildFilterActiveChip(
                          _timeFilter == 'last_24h' 
                              ? 'Last 24h' 
                              : _timeFilter == 'last_week' 
                                  ? 'Last Week' 
                                  : 'Last Month',
                          onClear: () {
                            setState(() {
                              _timeFilter = 'all';
                            });
                            _applyFilters();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterActiveChip(String label, {required VoidCallback onClear}) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primary),
          ),
        ],
      ),
    );
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
          // Available tab
          dataProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStickyFilterBar(),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () async => _applyFilters(),
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
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: dataProvider.services.length,
                                itemBuilder: (context, index) {
                                  final service = dataProvider.services[index];
                                  return ServiceCard(
                                    title: service.title,
                                    description: service.description,
                                    imageUrl: (service.images.isNotEmpty && service.images.first.isNotEmpty) ? service.images.first : null,
                                    budget: service.budget,
                                    authorName: service.createdBy is User ? (service.createdBy as User).name : (service.createdBy is Map ? service.createdBy['name'] ?? 'Unknown' : 'Customer'),
                                    location: service.location,
                                    jobTypes: service.jobTypes,
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
                    ),
                  ],
                ),

          // My applications tab
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
                    child: Text('My Price: ${req['estimatedPrice']} DA', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
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
