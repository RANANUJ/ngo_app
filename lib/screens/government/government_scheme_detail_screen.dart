import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GovernmentSchemeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;

  const GovernmentSchemeDetailScreen({
    Key? key,
    required this.scheme,
  }) : super(key: key);

  @override
  State<GovernmentSchemeDetailScreen> createState() => _GovernmentSchemeDetailScreenState();
}

class _GovernmentSchemeDetailScreenState extends State<GovernmentSchemeDetailScreen> {
  static const Color primary = Color(0xFF0099B8);

  bool _isDetailsExpanded = false;
  bool _isRequirementsExpanded = false;
  bool _isBenefitsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final requirements = (scheme['requirements'] ?? '').toString().split('\n').where((s) => s.trim().isNotEmpty).toList();
    final benefits = (scheme['benefits'] ?? '').toString().split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Program Details',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme['name'] ?? 'Scheme',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (scheme['subtitle'] != null && scheme['subtitle'].toString().isNotEmpty)
                    Text(
                      scheme['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Banner image
            if (scheme['imageUrl'] != null && scheme['imageUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    scheme['imageUrl'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance, size: 50, color: primary),
                            const SizedBox(height: 8),
                            Text(
                              scheme['name'] ?? 'Scheme',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (scheme['logoUrl'] != null && scheme['logoUrl'].toString().isNotEmpty)
                          Image.network(
                            scheme['logoUrl'],
                            height: 80,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.account_balance, size: 50, color: primary),
                          )
                        else
                          Icon(Icons.account_balance, size: 50, color: primary),
                        const SizedBox(height: 8),
                        Text(
                          scheme['name'] ?? 'Scheme',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Program Details section
            _buildSectionTitle('Program Details'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scheme['description'] ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    maxLines: _isDetailsExpanded ? null : 3,
                    overflow: _isDetailsExpanded ? null : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDetailsExpanded = !_isDetailsExpanded;
                      });
                    },
                    child: Text(
                      _isDetailsExpanded ? 'View less' : 'View more',
                      style: TextStyle(
                        color: primary,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Requirements section
            if (requirements.isNotEmpty) ...[
              _buildSectionTitle('Requirements'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...((_isRequirementsExpanded ? requirements : requirements.take(2)).map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                          Expanded(
                            child: Text(
                              req.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
                    if (requirements.length > 2)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isRequirementsExpanded = !_isRequirementsExpanded;
                          });
                        },
                        child: Text(
                          _isRequirementsExpanded ? 'View less' : 'View more',
                          style: TextStyle(
                            color: primary,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Benefits section
            if (benefits.isNotEmpty) ...[
              _buildSectionTitle('Benefits'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...((_isBenefitsExpanded ? benefits : benefits.take(2)).map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                          Expanded(
                            child: Text(
                              benefit.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
                    if (benefits.length > 2)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBenefitsExpanded = !_isBenefitsExpanded;
                          });
                        },
                        child: Text(
                          _isBenefitsExpanded ? 'View less' : 'View more',
                          style: TextStyle(
                            color: primary,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Apply button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _applyForScheme(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Apply',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  Future<void> _applyForScheme() async {
    final applyLink = widget.scheme['applyLink'];
    
    if (applyLink != null && applyLink.toString().isNotEmpty) {
      try {
        final uri = Uri.parse(applyLink);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showApplyDialog();
        }
      } catch (e) {
        _showApplyDialog();
      }
    } else {
      _showApplyDialog();
    }
  }

  void _showApplyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primary),
            const SizedBox(width: 8),
            const Text('Apply for Scheme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To apply for "${widget.scheme['name']}", please visit the official government portal or your nearest government office.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              'Required Documents:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Aadhaar Card\n• Income Certificate\n• Residence Proof\n• Bank Account Details',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application process initiated. Check your email for further instructions.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Register Interest', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
