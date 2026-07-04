import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/resource.dart';
import '../controllers/resource_controller.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String currentNgoId;

  const ResourceDetailScreen({
    Key? key,
    required this.data,
    required this.docId,
    required this.currentNgoId,
  }) : super(key: key);

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final _messageController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;
  late final Resource _fallbackResource;

  @override
  void initState() {
    super.initState();
    _fallbackResource = Resource.fromMap(widget.docId, widget.data);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Resource>(
      stream: context.read<ResourceController>().streamResourceDetails(widget.docId),
      builder: (context, snapshot) {
        final resource = snapshot.data ?? _fallbackResource;
        
        final title = resource.title;
        final description = resource.description;
        final quantity = resource.quantity;
        final category = resource.category;
        final ngoName = resource.ngoName;
        final ngoId = resource.ngoId;
        final images = resource.images;
        final status = resource.status;
        
        final isOwnResource = ngoId == widget.currentNgoId;
        
        final dateStr = '${resource.createdAt.day}/${resource.createdAt.month}/${resource.createdAt.year}';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isNotEmpty
                      ? Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primary.withValues(alpha: 0.3),
                            child: const Icon(Icons.inventory_2, size: 80, color: Colors.white),
                          ),
                        )
                      : Container(
                          color: primary.withValues(alpha: 0.3),
                          child: const Icon(Icons.inventory_2, size: 80, color: Colors.white),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge & Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'available' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NGO Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.business, color: primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ngoName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Shared on $dateStr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwnResource)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Your Resource',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quantity Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2, color: primary, size: 32),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                                const Text(
                                  'Available Quantity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          description.isNotEmpty ? description : 'No description provided',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // All Images
                      if (images.length > 1) ...[
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                        ),
                      ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    images[index],
                                    width: 150,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 80), // Space for button
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isOwnResource && status == 'available'
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () => _showRequestDialog(quantity, resource),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Request Resource',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : isOwnResource
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _deleteResource(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Delete'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _toggleResourceStatus(status),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 'available' ? Colors.orange : Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  status == 'available' ? 'Mark Unavailable' : 'Mark Available',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
        );
      },
    );
  }

  void _showRequestDialog(int availableQty, Resource resource) {
    _quantityController.text = '1';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake, color: primary, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Request Resource',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity Needed (Max: $availableQty)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message to NGO (Optional)',
                hintText: 'Explain why you need this resource...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Request button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _sendRequest(availableQty, resource),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Send Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(int maxQty, Resource resource) async {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0 || qty > maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid quantity (1-$maxQty)'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await context.read<ResourceController>().submitRequest(
        resourceId: widget.docId,
        resourceName: resource.title,
        requestingNgoId: widget.currentNgoId,
        ownerNgoId: resource.ngoId,
        quantity: qty,
        message: _messageController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _quantityController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteResource() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<ResourceController>().deleteResource(widget.docId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _toggleResourceStatus(String currentStatus) async {
    final success = await context.read<ResourceController>().toggleResourceStatus(widget.docId, currentStatus);
    if (success && mounted) {
      final newStatus = currentStatus == 'available' ? 'unavailable' : 'available';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resource marked as $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
