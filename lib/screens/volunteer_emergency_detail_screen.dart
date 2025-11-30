import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerEmergencyDetailScreen extends StatefulWidget {
  final String emergencyId;
  final Map<String, dynamic> emergencyData;
  const VolunteerEmergencyDetailScreen({super.key, required this.emergencyId, required this.emergencyData});
  @override
  State<VolunteerEmergencyDetailScreen> createState() => _VolunteerEmergencyDetailScreenState();
}

class _VolunteerEmergencyDetailScreenState extends State<VolunteerEmergencyDetailScreen> {
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
      await FirebaseFirestore.instance.collection('emergency_donations_records').add({
        'emergencyId': widget.emergencyId,
        'donorId': user?.uid,
        'donorEmail': _isAnonymous ? 'Anonymous' : user?.email,
        'amount': amount,
        'isAnonymous': _isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('emergency_donations').doc(widget.emergencyId).update({
        'collectedAmount': FieldValue.increment(amount),
      });
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your donation!'))); }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.emergencyData;
    final progress = (data['collectedAmount'] ?? 0) / (data['targetAmount'] ?? 1);
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['title'] ?? 'Emergency', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(primaryColor), minHeight: 10),
              const SizedBox(height: 8),
              Text('₹${data['collectedAmount'] ?? 0} raised of ₹${data['targetAmount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          Text(data['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
          const SizedBox(height: 24),
          const Text('Make a Donation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    );
  }
}
