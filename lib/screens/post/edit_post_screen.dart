import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/post.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../../utils/image_utils.dart';
import 'dart:convert';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isLoading = false;
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _existingImages = List.from(widget.post.images);
    _titleController = TextEditingController(text: widget.post.title);
    _descController = TextEditingController(text: widget.post.description ?? '');
  }

  Future<void> _deleteExistingImage(int index) async {
    if (_existingImages.length + _newImages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A post must have at least one image')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().deletePostImage(widget.post.id, index);
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
    if (_newImages.length + _existingImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed total')));
      return;
    }
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        _newImages.addAll(selected);
        final totalAllowed = 5 - _existingImages.length;
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
    
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload at least one image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'description': _descController.text.isEmpty ? null : _descController.text,
      };

      List<MultipartFile> imageFiles = [];
      for (var image in _newImages) {
        final bytes = await image.readAsBytes();
        imageFiles.add(MultipartFile.fromBytes(bytes, filename: image.name));
      }
      if (imageFiles.isNotEmpty) data['images'] = imageFiles;
      
      final formData = FormData.fromMap(data);

      await ApiService().updatePost(widget.post.id, formData);
      
      if (mounted) {
        context.read<DataProvider>().fetchAllPosts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated successfully!')));
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
      appBar: AppBar(
        title: const Text('Edit Post', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Image Section ──
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
                            Icon(Icons.photo_library_outlined, color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Post Portfolio Images (Max 5)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Add button
                              InkWell(
                                onTap: _pickImages,
                                child: Container(
                                  width: 100, height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 30),
                                      SizedBox(height: 4),
                                      Text('Add Pic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
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
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(hintText: 'Describe your work...'),
                          maxLines: 4,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save Button ──
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
