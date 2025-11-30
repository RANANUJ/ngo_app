import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'volunteer_impact_detail_screen.dart';

class VolunteerImpactsScreen extends StatelessWidget {
  const VolunteerImpactsScreen({super.key});
  static const Color primaryColor = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impact Stories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: primaryColor, iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('impact_stories').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No impact stories yet'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerImpactDetailScreen(impactId: doc.id, impactData: data))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (data['imageUrl'] != null) Image.network(data['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 60, color: Colors.grey))),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['title'] ?? 'Impact Story', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(data['description'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [Icon(Icons.people, size: 18, color: primaryColor), const SizedBox(width: 4), Text('${data['beneficiaries'] ?? 0} beneficiaries', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))]),
                          ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerImpactDetailScreen(impactId: doc.id, impactData: data))), style: ElevatedButton.styleFrom(backgroundColor: primaryColor), child: const Text('Support', style: TextStyle(color: Colors.white))),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
