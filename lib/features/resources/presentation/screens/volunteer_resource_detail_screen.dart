import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/resource.dart';
import '../controllers/resource_controller.dart';

class VolunteerResourceDetailScreen extends StatefulWidget {
  final String resourceId;
  final Map<String, dynamic> resourceData;

  const VolunteerResourceDetailScreen({
    super.key, 
    required this.resourceId, 
    required this.resourceData,
  });

  @override
  State<VolunteerResourceDetailScreen> createState() => _VolunteerResourceDetailScreenState();
}

class _VolunteerResourceDetailScreenState extends State<VolunteerResourceDetailScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final _messageController = TextEditingController();
  late final Resource _fallbackResource;

  @override
  void initState() {
    super.initState();
    _fallbackResource = Resource.fromMap(widget.resourceId, widget.resourceData);
  }

  @override
  void dispose() { 
    _quantityController.dispose(); 
    _purposeController.dispose(); 
    _messageController.dispose(); 
    super.dispose(); 
  }

  Future<void> _submitRequest(Resource resource) async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = FirebaseAuth.instance.currentUser;
    final qty = int.tryParse(_quantityController.text) ?? 0;

    final success = await context.read<ResourceController>().submitRequest(
      resourceId: widget.resourceId,
      resourceName: resource.title,
      requesterId: user?.uid,
      requesterEmail: user?.email,
      quantity: qty,
      purpose: _purposeController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (success && mounted) { 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully!')),
      ); 
    } else if (mounted) {
      final error = context.read<ResourceController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Resource>(
      stream: context.read<ResourceController>().streamResourceDetails(widget.resourceId),
      builder: (context, snapshot) {
        final resource = snapshot.data ?? _fallbackResource;
        final title = resource.title;
        final category = resource.category;
        final quantity = resource.quantity;
        final ngoName = resource.ngoName;
        final description = resource.description;

        final controller = context.watch<ResourceController>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Resource Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
            backgroundColor: primaryColor, 
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      _buildInfoRow('Category', category),
                      _buildInfoRow('Available Quantity', '$quantity'),
                      _buildInfoRow('Provided by', ngoName),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8), 
                        Text(description, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Request Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Form(
                  key: _formKey, 
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity Needed', 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter quantity';
                          final qty = int.tryParse(v);
                          if (qty == null || qty <= 0) return 'Enter a valid quantity';
                          if (qty > quantity) return 'Cannot exceed available quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _purposeController,
                        decoration: InputDecoration(
                          labelText: 'Purpose', 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter purpose' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Additional Message (Optional)', 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: ElevatedButton(
                    onPressed: controller.isLoading ? null : () => _submitRequest(resource),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)), 
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
