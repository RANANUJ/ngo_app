import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/models/campaign.dart';
import '../controllers/campaign_controller.dart';
import 'campaign_detail_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class VolunteerMyCampaignsScreen extends StatefulWidget {
  const VolunteerMyCampaignsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerMyCampaignsScreen> createState() => _VolunteerMyCampaignsScreenState();
}

class _VolunteerMyCampaignsScreenState extends State<VolunteerMyCampaignsScreen> {
  static const Color primary = Color(0xFF0099B8);
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CampaignController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Campaigns'),
      ),
      body: _userId == null
          ? const Center(child: Text('Please login to view your campaigns'))
          : StreamBuilder<List<Campaign>>(
              stream: controller.streamJoinedCampaigns(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListSkeleton(itemCount: 3, height: 120);
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final campaigns = snapshot.data ?? [];

                if (campaigns.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return _buildCampaignCard(campaign);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Campaigns Joined',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start making an impact by joining campaigns',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Campaigns'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    final title = campaign.title;
    final description = campaign.description;
    final imageUrl = campaign.images.isNotEmpty ? campaign.images[0] : '';
    final ngoName = campaign.ngoName;
    final status = campaign.status;
    final targetAmount = campaign.targetAmount;
    final raisedAmount = campaign.raisedAmount;
    final progress = targetAmount > 0 ? (raisedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailScreen(
              campaign: campaign,
              isVolunteerView: true,
              isNgoView: false,
            ),
          ),
        ).then((_) {
          setState(() {});
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 150,
                            color: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.campaign, size: 50, color: primary),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 150,
                          color: primary.withValues(alpha: 0.1),
                          child: Icon(Icons.campaign, size: 50, color: primary),
                        ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // NGO Name
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ngoName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  if (targetAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_formatAmount(raisedAmount)} raised',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        Text(
                          'of ₹${_formatAmount(targetAmount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      default:
        return status.toUpperCase();
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
