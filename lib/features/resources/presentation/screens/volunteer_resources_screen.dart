import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/resource.dart';
import '../controllers/resource_controller.dart';
import 'volunteer_resource_detail_screen.dart';

class VolunteerResourcesScreen extends StatefulWidget {
  const VolunteerResourcesScreen({super.key});
  
  @override
  State<VolunteerResourcesScreen> createState() => _VolunteerResourcesScreenState();
}

class _VolunteerResourcesScreenState extends State<VolunteerResourcesScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Clothing', 'Medical', 'Education', 'Shelter', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: primaryColor, 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.white : Colors.black),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Resource>>(
              stream: context.read<ResourceController>().streamAvailableResources(category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final resources = snapshot.data ?? [];
                if (resources.isEmpty) {
                  return const Center(child: Text('No resources available'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final resource = resources[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => VolunteerResourceDetailScreen(
                              resourceId: resource.id, 
                              resourceData: resource.toMap(),
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60, 
                                height: 60, 
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1), 
                                  borderRadius: BorderRadius.circular(12),
                                ), 
                                child: Icon(_getCategoryIcon(resource.category), color: primaryColor, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(resource.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Qty: ${resource.quantity}', style: TextStyle(color: Colors.grey.shade600)),
                                    Text('By: ${resource.ngoName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => VolunteerResourceDetailScreen(
                                      resourceId: resource.id, 
                                      resourceData: resource.toMap(),
                                    ),
                                  ),
                                ), 
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor), 
                                child: const Text('Request', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'clothing': return Icons.checkroom;
      case 'medical': return Icons.medical_services;
      case 'medicine': return Icons.medical_services;
      case 'education': return Icons.school;
      case 'books': return Icons.book;
      case 'shelter': return Icons.home;
      default: return Icons.inventory;
    }
  }
}
