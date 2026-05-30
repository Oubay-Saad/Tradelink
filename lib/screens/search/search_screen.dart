import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../profile/user_profile_screen.dart';
import '../../utils/image_utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<User> _results = [];
  bool _isLoading = false;
  

  String _selectedRole = 'All';
  String _selectedLocation = '';
  String _selectedJobType = 'All';
  double _minExperience = 0;

  List<Map<String, dynamic>> _backendJobTypes = [];
  List<String> _jobTypeLabels = ['All'];
  List<Map<String, dynamic>> _wilayas = [];

  bool get _hasActiveFilters => _selectedRole != 'All' || _selectedLocation.isNotEmpty || _selectedJobType != 'All' || _minExperience > 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final types = await ApiService().getJobTypes();
      final wilayas = await ApiService().getWilayas();
      setState(() {
        _backendJobTypes = types;
        _jobTypeLabels = ['All', ...types.map((jt) => jt['en'] as String)];
        _wilayas = wilayas;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch());
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && !_hasActiveFilters) {
      setState(() { _results = []; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      String? jobTypeValue;
      if (_selectedJobType != 'All') {
        final match = _backendJobTypes.firstWhere((jt) => jt['en'] == _selectedJobType, orElse: () => {});
        jobTypeValue = match['value'] as String?;
      }
      final results = await ApiService().searchTradesmen(
        name: query,
        location: _selectedLocation,
        jobType: jobTypeValue ?? _selectedJobType,
        experience: _minExperience.toInt(),
        role: _selectedRole,
      );
      setState(() => _results = results);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterModal() {
    String tempRole = _selectedRole;
    String tempLocation = _selectedLocation;
    String tempJobType = _selectedJobType;
    double tempExperience = _minExperience;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() { tempRole = 'All'; tempLocation = ''; tempJobType = 'All'; tempExperience = 0; });
                      },
                      child: const Text('Reset', style: TextStyle(color: AppTheme.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),


                const Text('Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'tradesman', label: Text('Tradesmen')),
                    ButtonSegment(value: 'customer', label: Text('Customers')),
                  ],
                  selected: {tempRole},
                  onSelectionChanged: (Set<String> newSelection) {
                    setModalState(() => tempRole = newSelection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedBackgroundColor: AppTheme.primary.withOpacity(0.1),
                    selectedForegroundColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),


                const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _wilayas.any((w) => w['name'] == tempLocation) ? tempLocation : null,
                  decoration: InputDecoration(
                    hintText: 'Any location',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.divider)),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 300,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Any location')),
                    ..._wilayas.map((w) => DropdownMenuItem(value: w['name'] as String, child: Text('${w['code']} - ${w['name']}'))),
                  ],
                  onChanged: (v) => setModalState(() => tempLocation = v ?? ''),
                ),
                const SizedBox(height: 20),
                

                const Text('Profession', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempJobType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.divider)),
                  ),
                  items: _jobTypeLabels.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) { if (val != null) setModalState(() => tempJobType = val); },
                ),
                const SizedBox(height: 20),
                

                Row(
                  children: [
                    const Text('Min Experience', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text('${tempExperience.toInt()} years', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary, fontSize: 13)),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primary,
                    thumbColor: AppTheme.primary,
                    inactiveTrackColor: AppTheme.divider,
                    overlayColor: AppTheme.primary.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: tempExperience,
                    min: 0, max: 20, divisions: 20,
                    onChanged: (val) => setModalState(() => tempExperience = val),
                  ),
                ),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedRole = tempRole;
                        _selectedLocation = tempLocation;
                        _selectedJobType = tempJobType;
                        _minExperience = tempExperience;
                      });
                      Navigator.pop(context);
                      _performSearch();
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search tradesmen...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () { _searchController.clear(); _performSearch(); })
                          : null,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: _hasActiveFilters ? AppTheme.primary : AppTheme.divider),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.tune_rounded, color: _hasActiveFilters ? Colors.white : AppTheme.textSecondary, size: 20),
                        if (_hasActiveFilters)
                          Positioned(
                            top: -4, right: -4,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),


          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedRole != 'All') _buildActiveChip(_selectedRole == 'tradesman' ? 'Tradesmen' : 'Customers', () => setState(() { _selectedRole = 'All'; _performSearch(); })),
                    if (_selectedLocation.isNotEmpty) _buildActiveChip('📍 $_selectedLocation', () => setState(() { _selectedLocation = ''; _performSearch(); })),
                    if (_selectedJobType != 'All') _buildActiveChip('🛠 $_selectedJobType', () => setState(() { _selectedJobType = 'All'; _performSearch(); })),
                    if (_minExperience > 0) _buildActiveChip('${_minExperience.toInt()}+ yrs', () => setState(() { _minExperience = 0; _performSearch(); })),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty && !_hasActiveFilters ? Icons.search_rounded : Icons.search_off_rounded,
                              size: 56, color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty && !_hasActiveFilters ? 'Search for tradesmen' : 'No results found',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                            ),
                            if (_searchController.text.isEmpty && !_hasActiveFilters)
                              const Text('Try a name or use filters', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) => _buildResultCard(_results[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary)),
        deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
        onDeleted: onRemove,
        backgroundColor: AppTheme.primary.withOpacity(0.08),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildResultCard(User user) {
    final jobType = (user.tradesmanInfo?.jobTypes.isNotEmpty == true)
        ? user.tradesmanInfo!.jobTypes.first.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id))),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ImageUtils.buildCircleAvatar(imageUrl: user.profilePic, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (jobType != null) ...[
                          Icon(Icons.build_rounded, size: 12, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(jobType, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                        if (user.location != null && user.location!.isNotEmpty) ...[
                          if (jobType != null) const Text('  ·  ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          Icon(Icons.location_on, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 2),
                          Flexible(child: Text(user.location!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (user.tradesmanInfo?.experience != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text('${user.tradesmanInfo!.experience} yrs', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
