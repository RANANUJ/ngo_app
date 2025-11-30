import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerResourceDetailScreen extends StatefulWidget {
  final String resourceId;
  final Map<String, dynamic> resourceData;
  const VolunteerResourceDetailScreen({super.key, required this.resourceId, required this.resourceData});
  @override
  State<VolunteerResourceDetailScreen> createState() => _VolunteerResourceDetailScreenState();
}

class _VolunteerResourceDetailScreenState extends State<VolunteerResourceDetailScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _quantityController.dispose(); _purposeController.dispose(); _messageController.dispose(); super.dispose(); }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('resource_requests').add({
        'resourceId': widget.resourceId,
        'resourceName': widget.resourceData['name'],
        'requesterId': user?.uid,
        'requesterEmail': user?.email,
        'quantityRequested': int.parse(_quantityController.text),
        'purpose': _purposeController.text,
        'message': _messageController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully!'))); }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.resourceData;
    return Scaffold(
      appBar: AppBar(title: const Text('Resource Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['name'] ?? 'Resource', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildInfoRow('Category', data['category'] ?? 'N/A'),
              _buildInfoRow('Available Quantity', '${data['quantity'] ?? 'N/A'}'),
              _buildInfoRow('Provided by', data['ngoName'] ?? 'NGO'),
              if (data['description'] != null) ...[const SizedBox(height: 8), Text(data['description'], style: TextStyle(color: Colors.grey.shade700))],
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Request Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Form(key: _formKey, child: Column(children: [
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity Needed', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.numbers)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter quantity';
                final qty = int.tryParse(v);
                if (qty == null || qty <= 0) return 'Enter a valid quantity';
                if (qty > (data['quantity'] ?? 0)) return 'Cannot exceed available quantity';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purposeController,
              decoration: InputDecoration(labelText: 'Purpose', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.description)),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter purpose' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Additional Message (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ])),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]),
  );
}
