import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import '../../domain/models/resource.dart';
import '../controllers/resource_controller.dart';
import 'resource_detail_screen.dart';

class ShareResourceScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const ShareResourceScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<ShareResourceScreen> createState() => _ShareResourceScreenState();
}

class _ShareResourceScreenState extends State<ShareResourceScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResourceController>().seedSampleResourcesIfNeeded(
        widget.ngoData.id,
        widget.ngoData.ngoName,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Share Resource',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Available Resources'),
              Tab(text: 'Share New'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildResourcesList(),
            _ShareResourceForm(ngoData: widget.ngoData),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesList() {
    return StreamBuilder<List<Resource>>(
      stream: context.read<ResourceController>().streamAvailableResources(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading resources: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        final resources = snapshot.data ?? [];

        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No shared resources yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final resource = resources[index];
            return _buildResourceCard(resource);
          },
        );
      },
    );
  }

  Widget _buildResourceCard(Resource resource) {
    final title = resource.title;
    final description = resource.description;
    final quantity = resource.quantity;
    final category = resource.category;
    final ngoName = resource.ngoName;
    final isOwnResource = resource.ngoId == widget.ngoData.id;
    
    String timeAgo = '';
    final diff = DateTime.now().difference(resource.createdAt);
    if (diff.inDays > 0) {
      timeAgo = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = 'Just now';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(
              data: resource.toMap(),
              docId: resource.id,
              currentNgoId: widget.ngoData.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  ngoName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                if (isOwnResource)
                  Text(
                    'Your Resource',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareResourceForm extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const _ShareResourceForm({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<_ShareResourceForm> createState() => _ShareResourceFormState();
}

class _ShareResourceFormState extends State<_ShareResourceForm> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String _category = 'Food';
  final List<File> _selectedImages = [];

  final List<String> _categories = [
    'Food',
    'Clothing',
    'Medicine',
    'Books',
    'Electronics',
    'Furniture',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _shareResource() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<ResourceController>().shareResource(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 1,
      category: _category,
      ngoId: widget.ngoData.id,
      ngoName: widget.ngoData.ngoName,
      imageFiles: _selectedImages,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _titleController.clear();
      _descriptionController.clear();
      _quantityController.clear();
      setState(() => _selectedImages.clear());
      
      DefaultTabController.of(context).animateTo(0);
    } else if (mounted) {
      final error = context.read<ResourceController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResourceController>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Resource Title'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g., Winter Clothes'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Describe the resource'),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: _inputDecoration(''),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Quantity'),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('e.g., 10'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final q = int.tryParse(v);
                          if (q == null || q <= 0) return 'Invalid Qty';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel('Upload Images (Optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: primary),
                    SizedBox(height: 8),
                    Text(
                      'Tap to pick images',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isLoading ? null : _shareResource,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Share Resource',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    );
  }
}
