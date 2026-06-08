import 'package:flutter/material.dart';
import 'package:ngo_app/screens/donations/payment_donation_screen.dart';

class VolunteerEmergencyDetailScreen extends StatefulWidget {
  final String emergencyId;
  final Map<String, dynamic> emergencyData;
  const VolunteerEmergencyDetailScreen({super.key, required this.emergencyId, required this.emergencyData});
  @override
  State<VolunteerEmergencyDetailScreen> createState() => _VolunteerEmergencyDetailScreenState();
}

class _VolunteerEmergencyDetailScreenState extends State<VolunteerEmergencyDetailScreen> {
  static const Color primaryColor = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    final data = widget.emergencyData;
    final progress = (data['collectedAmount'] ?? 0) / (data['targetAmount'] ?? 1);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Emergency', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(primaryColor),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '?${data['collectedAmount'] ?? 0} raised of ?${data['targetAmount'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(data['description'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentDonationScreen(
                      campaignId: widget.emergencyId,
                      campaignTitle: data['title'] ?? 'Emergency',
                      campaignDescription: data['description'],
                      goalAmount: data['targetAmount'],
                      raisedAmount: data['collectedAmount'],
                      donationType: 'emergency',
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Donate Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
