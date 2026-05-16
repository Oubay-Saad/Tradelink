import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../../utils/image_utils.dart';

class EditServiceScreen extends StatefulWidget {
  final ServiceItem service;
  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _budgetController;
  bool _isLoading = false;
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _existingImages = List.from(widget.service.images);
    _titleController = TextEditingController(text: widget.service.title);
    _descController = TextEditingController(text: widget.service.description ?? '');
    _budgetController = TextEditingController(text: widget.service.budget.toString());
  }

  Future<void> _deleteExistingImage(int index) async {
    setState(() => _isLoading = true);
    try {
      await ApiService().deleteServiceImage(widget.service.id, index);
      setState(() {
        _existingImages.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete image'), backgroundColor: AppTheme.error));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    if (_newImages.length + _existingImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 images allowed total')));
      return;
    }
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        _newImages.addAll(selected);
        final totalAllowed = 3 - _existingImages.length;
        if (_newImages.length > totalAllowed) {
          _newImages.removeRange(totalAllowed, _newImages.length);
        }
      });
    }
  }

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }
    
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'description': _descController.text.isEmpty ? null : _descController.text,
        'budget': _budgetController.text.isNotEmpty ? double.parse(_budgetController.text) : 0.0,
      };

      List<MultipartFile> imageFiles = [];
      for (var image in _newImages) {
        final bytes = await image.readAsBytes();
        imageFiles.add(MultipartFile.fromBytes(bytes, filename: image.name));
      }
      if (imageFiles.isNotEmpty) data['images'] = imageFiles;
      
      final formData = FormData.fromMap(data);

      await ApiService().editService(widget.service.id, formData);
      
      if (mounted) {
        context.read<DataProvider>().fetchServices();
        context.read<DataProvider>().fetchMyServices();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service updated successfully!')));
        Navigator.pop(context, true); // return true to indicate success
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) errorMsg = e.response?.data?['error'] ?? e.message ?? e.toString();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errorMsg'), backgroundColor: AppTheme.error));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Images Section ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      Text('${_newImages.length + _existingImages.length}/3', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add button
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100, height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: AppTheme.primary, size: 28),
                                SizedBox(height: 4),
                                Text('Add', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        // Existing images
                        ..._existingImages.asMap().entries.map((e) => Stack(
                          children: [
                            Container(
                              width: 100, height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                child: Image(
                                  image: ImageUtils.getImageProvider(e.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2, right: 10,
                              child: GestureDetector(
                                onTap: () => _deleteExistingImage(e.key),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),
                        // Preview new images
                        ..._newImages.asMap().entries.map((e) => Stack(
                          children: [
                            Container(
                              width: 100, height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                child: kIsWeb
                                    ? Image.network(e.value.path, fit: BoxFit.cover)
                                    : Image.file(io.File(e.value.path), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 2, right: 10,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(e.key),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Details Section ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Give it a title'),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(hintText: 'Describe your work or service...'),
                    maxLines: 4,
                    maxLength: 800,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _budgetController,
                    decoration: const InputDecoration(hintText: 'Budget (\$)', prefixIcon: Icon(Icons.attach_money_rounded)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Save Changes'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
