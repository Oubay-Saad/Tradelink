import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _experienceController = TextEditingController();
  String _role = 'customer';
  String? _selectedWilaya;
  bool _obscurePassword = true;

  List<Map<String, dynamic>> _allJobTypes = [];
  List<Map<String, dynamic>> _wilayas = [];
  List<String> _selectedJobTypes = [];
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final types = await ApiService().getJobTypes();
      final wilayas = await ApiService().getWilayas();
      setState(() { _allJobTypes = types; _wilayas = wilayas; _loadingData = false; });
    } catch (e) {
      setState(() => _loadingData = false);
    }
  }

  void _register() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number must be exactly 10 digits')));
      return;
    }
    if (_role == 'tradesman' && _selectedJobTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one job type')));
      return;
    }

    final success = await context.read<AuthProvider>().register(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _role,
      jobTypes: _role == 'tradesman' ? _selectedJobTypes : null,
      location: _selectedWilaya,
      experience: _role == 'tradesman' ? int.tryParse(_experienceController.text) : null,
    );
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful, please login')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Registration failed')),
      );
    }
  }

  void _showJobTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      // Handle
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Select Specializations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          TextButton(
                            onPressed: () { setState(() => _selectedJobTypes = tempSelected); Navigator.pop(context); },
                            child: const Text('Done', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(hintText: 'Search job types...', prefixIcon: Icon(Icons.search_rounded)),
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
                              title: Text(label, style: const TextStyle(fontSize: 14)),
                              value: isSelected,
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) tempSelected.add(value);
                                  else tempSelected.remove(value);
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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Join the TradeLink community', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                  ],
                ),
              ),

              // ── Form ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('Full Name'),
                    TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline_rounded))),
                    const SizedBox(height: 16),

                    _buildLabel('Phone Number'),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(hintText: '0550000000', prefixIcon: Icon(Icons.phone_outlined), counterText: ''),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Email'),
                    TextField(controller: _emailController, decoration: const InputDecoration(hintText: 'name@example.com', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    _buildLabel('Wilaya'),
                    DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: const InputDecoration(hintText: 'Select your wilaya', prefixIcon: Icon(Icons.location_on_outlined)),
                      isExpanded: true,
                      menuMaxHeight: 300,
                      items: _wilayas.map((w) => DropdownMenuItem(value: w['name'] as String, child: Text('${w['code']} - ${w['name']}'))).toList(),
                      onChanged: (v) => setState(() => _selectedWilaya = v),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Password'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Account Type Selector ──
                    _buildLabel('I am a...'),
                    Row(
                      children: [
                        Expanded(child: _buildRoleOption('customer', 'Customer', Icons.person_rounded, 'Hire professionals')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildRoleOption('tradesman', 'Tradesman', Icons.build_rounded, 'Offer services')),
                      ],
                    ),

                    // ── Tradesman Fields ──
                    if (_role == 'tradesman') ...[
                      const SizedBox(height: 20),
                      _buildLabel('Years of Experience'),
                      TextField(
                        controller: _experienceController,
                        decoration: const InputDecoration(hintText: 'e.g. 5', prefixIcon: Icon(Icons.timeline_rounded)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Specializations *'),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _loadingData ? null : _showJobTypePicker,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.handyman_rounded, color: AppTheme.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _loadingData
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
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedJobTypes.map((jt) => Chip(
                            label: Text(_getJobLabel(jt), style: const TextStyle(fontSize: 12)),
                            onDeleted: () => setState(() => _selectedJobTypes.remove(jt)),
                            deleteIconColor: AppTheme.error,
                            backgroundColor: AppTheme.primary.withOpacity(0.08),
                            labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          )).toList(),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Create Account'),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign In', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildRoleOption(String value, String label, IconData icon, String subtitle) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.primary.withOpacity(0.7) : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
