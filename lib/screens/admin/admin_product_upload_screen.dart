import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AdminProductUploadScreen extends StatefulWidget {
  const AdminProductUploadScreen({super.key});

  @override
  State<AdminProductUploadScreen> createState() => _AdminProductUploadScreenState();
}

class _AdminProductUploadScreenState extends State<AdminProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository();
  
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _sizesCtrl = TextEditingController();
  final _colorsCtrl = TextEditingController();
  
  bool _isFeatured = false;
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _sizesCtrl.dispose();
    _colorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docId = FirebaseFirestore.instance.collection('products').doc().id;
      List<String> imageUrls = [];

      // Upload Images
      for (int i = 0; i < _selectedImages.length; i++) {
        final ref = FirebaseStorage.instance
            .ref('products/$docId/image_$i.jpg');
        await ref.putFile(File(_selectedImages[i].path));
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Parse lists
      final sizes = _sizesCtrl.text.split(',')
          .map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final colors = _colorsCtrl.text.split(',')
          .map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Create Product
      final product = Product(
        id: docId,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        category: _categoryCtrl.text.trim(),
        stock: int.parse(_stockCtrl.text.trim()),
        isFeatured: _isFeatured,
        sizes: sizes,
        colors: colors,
        imageUrls: imageUrls,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
      );

      await _productRepo.createProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Images Section
                  Text('Product Images', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface2,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primary),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(File(_selectedImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 16,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54, shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields Section
                  AppTextField(
                    controller: _nameCtrl, label: 'Product Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(children: [
                    Expanded(child: AppTextField(
                      controller: _brandCtrl, label: 'Brand',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: AppTextField(
                      controller: _categoryCtrl, label: 'Category',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 16),
                  
                  Row(children: [
                    Expanded(child: AppTextField(
                      controller: _priceCtrl, label: 'Price (\$)',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: AppTextField(
                      controller: _stockCtrl, label: 'Stock Qty',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _descCtrl, label: 'Description',
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _sizesCtrl, label: 'Sizes (comma-separated, e.g. S, M, L)',
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _colorsCtrl, label: 'Colors (comma-separated, e.g. Red, Blue)',
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Featured Product'),
                    subtitle: const Text('Show on home screen banner'),
                    value: _isFeatured,
                    activeTrackColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isFeatured = val),
                  ),
                  const SizedBox(height: 32),

                  AppButton(
                    label: 'Upload Product',
                    onPressed: _uploadProduct,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
        ],
      ),
    );
  }
}
