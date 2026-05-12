import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isLoading = false;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        _images.addAll(selected);
        if (_images.length > 5) {
          _images.removeRange(5, _images.length);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userRole = context.read<AuthProvider>().currentUser?.role ?? 'customer';
      
      final Map<String, dynamic> data = {
        'title': _titleController.text,
        'description': _descController.text.isEmpty ? null : _descController.text,
      };

      if (userRole == 'customer') {
        data['budget'] = _budgetController.text.isNotEmpty ? int.parse(_budgetController.text) : 0;
      }

      // Add images to FormData
      List<MultipartFile> imageFiles = [];
      for (var image in _images) {
        final bytes = await image.readAsBytes();
        imageFiles.add(MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        ));
      }
      
      if (imageFiles.isNotEmpty) {
        data['images'] = imageFiles;
      }

      final formData = FormData.fromMap(data);

      if (userRole == 'tradesman') {
        await ApiService().createPost(formData);
      } else {
        await ApiService().createService(formData);
      }
      
      if (mounted) {
        context.read<DataProvider>().fetchServices();
        context.read<DataProvider>().fetchMyServices();
        context.read<DataProvider>().fetchAllPosts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Created successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.response?.data?['error'] ?? e.message ?? e.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = context.watch<AuthProvider>().currentUser?.role == 'customer';

    return Scaffold(
      appBar: AppBar(title: Text(isCustomer ? 'Request a Service' : 'Create Portfolio Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            if (isCustomer)
              TextField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Budget (\$)'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            const Text('Images (Max 5)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb 
                              ? Image.network(_images[index].path, fit: BoxFit.cover)
                              : Image.file(io.File(_images[index].path), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: -10,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Images'),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
          ],
        ),
      ),
    );
  }
}
