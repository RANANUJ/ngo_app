import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerImpactDetailScreen extends StatefulWidget {
  final String impactId;
  final Map<String, dynamic> impactData;
  const VolunteerImpactDetailScreen({super.key, required this.impactId, required this.impactData});
  @override
  State<VolunteerImpactDetailScreen> createState() => _VolunteerImpactDetailScreenState();
}

class _VolunteerImpactDetailScreenState extends State<VolunteerImpactDetailScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _selectedAmount;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _selectedAmount ?? int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount'))); return; }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('impact_donations').add({
        'impactId': widget.impactId,
        'impactTitle': widget.impactData['title'],
        'donorId': user?.uid,
        'donorEmail': _isAnonymous ? 'Anonymous' : user?.email,
        'amount': amount,
        'isAnonymous': _isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for supporting this cause!'))); }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.impactData;
    return Scaffold(
      appBar: AppBar(title: const Text('Impact Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (data['imageUrl'] != null) Image.network(data['imageUrl'], height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 250, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 80, color: Colors.grey))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['title'] ?? 'Impact Story', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.people, color: primaryColor), const SizedBox(width: 8), Text('${data['beneficiaries'] ?? 0} beneficiaries', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))]),
              const SizedBox(height: 16),
              Text(data['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 16, height: 1.5)),
              const SizedBox(height: 24),
              const Text('Support this Cause', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [100, 500, 1000, 5000, 10000].map((amt) => ChoiceChip(
                label: Text('₹$amt'),
                selected: _selectedAmount == amt,
                onSelected: (s) => setState(() { _selectedAmount = s ? amt : null; if (s) _amountController.clear(); }),
                selectedColor: primaryColor,
                labelStyle: TextStyle(color: _selectedAmount == amt ? Colors.white : Colors.black),
              )).toList()),
              const SizedBox(height: 16),
              Form(key: _formKey, child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Custom Amount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.currency_rupee)),
                onChanged: (_) => setState(() => _selectedAmount = null),
                validator: (v) => (_selectedAmount == null && (v == null || v.isEmpty)) ? 'Please enter or select an amount' : null,
              )),
              const SizedBox(height: 16),
              CheckboxListTile(title: const Text('Donate Anonymously'), value: _isAnonymous, onChanged: (v) => setState(() => _isAnonymous = v ?? false), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Donate Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
