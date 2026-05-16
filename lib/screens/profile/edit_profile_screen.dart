import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

import '../../utils/image_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _skillController;
  
  String? _selectedWilaya;
  List<String> _skills = [];
  List<String> _selectedJobTypes = [];
  List<Map<String, dynamic>> _allJobTypes = [];
  List<Map<String, dynamic>> _wilayas = [];
  Uint8List? _profilePicBytes;
  String? _profilePicName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name);
    _bioController = TextEditingController(text: user?.bio);
    _selectedWilaya = user?.location;
    _experienceController = TextEditingController(text: user?.tradesmanInfo?.experience?.toString());
    _skillController = TextEditingController();
    _skills = List.from(user?.tradesmanInfo?.skills ?? []);
    _selectedJobTypes = List.from(user?.tradesmanInfo?.jobTypes ?? []);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final types = await ApiService().getJobTypes();
      final wilayas = await ApiService().getWilayas();
      setState(() {
        _allJobTypes = types;
        _wilayas = wilayas;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profilePicBytes = bytes;
        _profilePicName = image.name;
      });
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _showJobTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        List<String> tempSelected = List.from(_selectedJobTypes);
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
                              setState(() => _selectedJobTypes = tempSelected);
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

  String _getJobLabel(String value) {
    final jt = _allJobTypes.firstWhere((j) => j['value'] == value, orElse: () => {});
    return (jt['en'] as String?) ?? value;
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final user = context.read<AuthProvider>().currentUser;
      final success = await context.read<AuthProvider>().updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        location: _selectedWilaya,
        experience: user?.role == 'tradesman' ? int.tryParse(_experienceController.text) : null,
        skills: user?.role == 'tradesman' ? _skills : null,
        jobTypes: user?.role == 'tradesman' ? _selectedJobTypes : null,
        profilePicBytes: _profilePicBytes,
        profilePicName: _profilePicName,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Update failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isTradesman = user?.role == 'tradesman';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Builder(
                      builder: (context) {
                        if (_profilePicBytes != null) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.divider, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.memory(_profilePicBytes!, fit: BoxFit.cover),
                            ),
                          );
                        }
                        
                        return ImageUtils.buildCircleAvatar(
                          imageUrl: user?.profilePic,
                          radius: 60,
                        );
                      }
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 24),

              const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _wilayas.any((w) => w['name'] == _selectedWilaya) ? _selectedWilaya : null,
                decoration: InputDecoration(
                  hintText: 'Select your wilaya',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                isExpanded: true,
                menuMaxHeight: 300,
                items: _wilayas.map((w) => DropdownMenuItem(
                  value: w['name'] as String,
                  child: Text('${w['code']} - ${w['name']}'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedWilaya = v),
              ),
              const SizedBox(height: 24),

              if (isTradesman) ...[
                const Text('Job Types', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _allJobTypes.isEmpty ? null : _showJobTypePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.handyman_rounded, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _allJobTypes.isEmpty
                              ? const Text('Loading...', style: TextStyle(color: AppTheme.textMuted))
                              : _selectedJobTypes.isEmpty
                                  ? const Text('Select your specializations', style: TextStyle(color: AppTheme.textMuted))
                                  : Text('${_selectedJobTypes.length} selected', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        ),
                        Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
                if (_selectedJobTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedJobTypes.map((jt) => Chip(
                      label: Text(_getJobLabel(jt)),
                      onDeleted: () => setState(() => _selectedJobTypes.remove(jt)),
                      deleteIconColor: AppTheme.error,
                      backgroundColor: AppTheme.primary.withOpacity(0.08),
                      labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                const Text('Experience (Years)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Years of experience',
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillController,
                        decoration: InputDecoration(
                          hintText: 'Add a skill...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onFieldSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addSkill,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _skills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () => _removeSkill(skill),
                    deleteIconColor: AppTheme.error,
                    backgroundColor: AppTheme.accent.withOpacity(0.08),
                    labelStyle: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
