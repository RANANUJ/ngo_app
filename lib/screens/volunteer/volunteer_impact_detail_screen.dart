import 'package:flutter/material.dart';
import 'package:ngo_app/screens/donations/payment_donation_screen.dart';

class VolunteerImpactDetailScreen extends StatefulWidget {
  final String impactId;
  final Map<String, dynamic> impactData;
  const VolunteerImpactDetailScreen({super.key, required this.impactId, required this.impactData});
  @override
  State<VolunteerImpactDetailScreen> createState() => _VolunteerImpactDetailScreenState();
}

class _VolunteerImpactDetailScreenState extends State<VolunteerImpactDetailScreen> {
  static const Color primaryColor = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    final data = widget.impactData;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null)
              Image.network(
                data['imageUrl'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? 'Impact Story', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${data['beneficiaries'] ?? 0} beneficiaries',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['description'] ?? '',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentDonationScreen(
                            campaignId: widget.impactId,
                            campaignTitle: data['title'] ?? 'Impact Story',
                            campaignDescription: data['description'],
                            donationType: 'impact',
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Support this Cause',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
