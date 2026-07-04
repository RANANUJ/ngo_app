import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/screens/government/government_scheme_detail_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  final bool isAdmin;

  const GovernmentSchemesScreen({
    Key? key,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Women',
    'Child',
    'Old age',
    'Health',
    'Education',
    'Agriculture',
    'Employment',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Government Schemes',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: primary),
                  onPressed: () => _showCreateSchemeDialog(),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search here...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mic, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Category chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Schemes list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('government_schemes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListSkeleton(itemCount: 4, height: 75);
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                // Filter by search and category
                final schemes = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? '';

                  final matchesSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      description.contains(_searchQuery);

                  final matchesCategory = _selectedCategory == 'All' ||
                      category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (schemes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No schemes found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.isAdmin) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add a new scheme',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final doc = schemes[index];
                    final scheme = doc.data() as Map<String, dynamic>;
                    scheme['id'] = doc.id;
                    return _buildSchemeCard(scheme, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme, String docId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GovernmentSchemeDetailScreen(scheme: scheme),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Scheme logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: scheme['logoUrl'] != null && scheme['logoUrl'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            scheme['logoUrl'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.account_balance, color: primary, size: 30),
                          ),
                        )
                      : Icon(Icons.account_balance, color: primary, size: 30),
                ),
                const SizedBox(width: 12),

                // Scheme details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme['name'] ?? 'Scheme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheme['shortDescription'] ?? scheme['description'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // View More button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GovernmentSchemeDetailScreen(scheme: scheme),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View More',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            // Admin actions
            if (widget.isAdmin) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  TextButton.icon(
                    onPressed: () => _showEditSchemeDialog(scheme, docId),
                    icon: Icon(Icons.edit_outlined, size: 18, color: primary),
                    label: Text(
                      'Edit',
                      style: TextStyle(color: primary, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(docId, scheme['name'] ?? 'Scheme'),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String docId, String schemeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Delete Scheme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$schemeName"?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteScheme(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteScheme(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('government_schemes')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting scheme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditSchemeDialog(Map<String, dynamic> scheme, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGovernmentSchemeScreen(
          scheme: scheme,
          docId: docId,
        ),
      ),
    );
  }

  void _showCreateSchemeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGovernmentSchemeScreen(),
      ),
    );
  }
}

// Create Government Scheme Screen (Admin only)
class CreateGovernmentSchemeScreen extends StatefulWidget {
  const CreateGovernmentSchemeScreen({Key? key}) : super(key: key);

  @override
  State<CreateGovernmentSchemeScreen> createState() => _CreateGovernmentSchemeScreenState();
}

class _CreateGovernmentSchemeScreenState extends State<CreateGovernmentSchemeScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _detailsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _applyLinkController = TextEditingController();

  String _selectedCategory = 'Women';
  bool _isLoading = false;

  final List<String> _categories = [
    'Women',
    'Child',
    'Old age',
    'Health',
    'Education',
    'Agriculture',
    'Employment',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _shortDescController.dispose();
    _detailsController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _logoUrlController.dispose();
    _imageUrlController.dispose();
    _applyLinkController.dispose();
    super.dispose();
  }

  Future<void> _createScheme() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('government_schemes').add({
        'name': _nameController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _detailsController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'benefits': _benefitsController.text.trim(),
        'category': _selectedCategory,
        'logoUrl': _logoUrlController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'applyLink': _applyLinkController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Scheme',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Scheme Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g., Beti Bachao, Beti Padhao'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Subtitle'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subtitleController,
                decoration: _inputDecoration('e.g., Program for Girl Child'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Category *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Select category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Short Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _shortDescController,
                maxLines: 2,
                decoration: _inputDecoration('Brief description for the card'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Program Details *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: _inputDecoration('Detailed description of the scheme'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Requirements'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _requirementsController,
                maxLines: 4,
                decoration: _inputDecoration('Enter each requirement on a new line'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Benefits'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: _inputDecoration('Enter each benefit on a new line'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Logo URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _logoUrlController,
                decoration: _inputDecoration('URL of scheme logo image'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Banner Image URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: _inputDecoration('URL of banner image'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Apply Link'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _applyLinkController,
                decoration: _inputDecoration('Official application URL'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createScheme,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Scheme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// Edit Government Scheme Screen (Admin only)
class EditGovernmentSchemeScreen extends StatefulWidget {
  final Map<String, dynamic> scheme;
  final String docId;

  const EditGovernmentSchemeScreen({
    Key? key,
    required this.scheme,
    required this.docId,
  }) : super(key: key);

  @override
  State<EditGovernmentSchemeScreen> createState() => _EditGovernmentSchemeScreenState();
}

class _EditGovernmentSchemeScreenState extends State<EditGovernmentSchemeScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _shortDescController;
  late TextEditingController _detailsController;
  late TextEditingController _requirementsController;
  late TextEditingController _benefitsController;
  late TextEditingController _logoUrlController;
  late TextEditingController _imageUrlController;
  late TextEditingController _applyLinkController;

  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Women',
    'Child',
    'Old age',
    'Health',
    'Education',
    'Agriculture',
    'Employment',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing scheme data
    _nameController = TextEditingController(text: widget.scheme['name'] ?? '');
    _subtitleController = TextEditingController(text: widget.scheme['subtitle'] ?? '');
    _shortDescController = TextEditingController(text: widget.scheme['shortDescription'] ?? '');
    _detailsController = TextEditingController(text: widget.scheme['description'] ?? '');
    _requirementsController = TextEditingController(text: widget.scheme['requirements'] ?? '');
    _benefitsController = TextEditingController(text: widget.scheme['benefits'] ?? '');
    _logoUrlController = TextEditingController(text: widget.scheme['logoUrl'] ?? '');
    _imageUrlController = TextEditingController(text: widget.scheme['imageUrl'] ?? '');
    _applyLinkController = TextEditingController(text: widget.scheme['applyLink'] ?? '');
    
    // Set category, default to 'Women' if not found
    String schemeCategory = widget.scheme['category'] ?? 'Women';
    _selectedCategory = _categories.contains(schemeCategory) ? schemeCategory : 'Women';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _shortDescController.dispose();
    _detailsController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _logoUrlController.dispose();
    _imageUrlController.dispose();
    _applyLinkController.dispose();
    super.dispose();
  }

  Future<void> _updateScheme() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('government_schemes')
          .doc(widget.docId)
          .update({
        'name': _nameController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _detailsController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'benefits': _benefitsController.text.trim(),
        'category': _selectedCategory,
        'logoUrl': _logoUrlController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'applyLink': _applyLinkController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Scheme',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Scheme Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g., Beti Bachao, Beti Padhao'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Subtitle'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subtitleController,
                decoration: _inputDecoration('e.g., Program for Girl Child'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Category *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Select category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Short Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _shortDescController,
                maxLines: 2,
                decoration: _inputDecoration('Brief description for the card'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Program Details *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: _inputDecoration('Detailed description of the scheme'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Requirements'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _requirementsController,
                maxLines: 4,
                decoration: _inputDecoration('Enter each requirement on a new line'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Benefits'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: _inputDecoration('Enter each benefit on a new line'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Logo URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _logoUrlController,
                decoration: _inputDecoration('URL of scheme logo image'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Banner Image URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: _inputDecoration('URL of banner image'),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Apply Link'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _applyLinkController,
                decoration: _inputDecoration('Official application URL'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateScheme,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Scheme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
