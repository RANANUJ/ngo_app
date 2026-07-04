import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/features/opportunities/presentation/screens/volunteer_opportunities_screen.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const VolunteerRegistrationScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  String _selectedGender = '';
  String _preferredType = 'Online';
  String _availability = 'Weekdays';
  String _commitment = 'One time';
  
  // Skills & Interest
  List<String> _selectedSkills = [];
  List<String> _selectedCauses = [];
  List<String> _selectedLanguages = [];
  String _selectedIdType = '';
  File? _idDocument;
  
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _skillOptions = [
    'Teaching', 'Medical', 'Technical', 'Administrative', 
    'Event Management', 'Communication', 'Photography', 
    'Writing', 'Social Media', 'Counseling', 'Legal', 'Other'
  ];
  
  final List<String> _causeOptions = [
    'Education', 'Healthcare', 'Environment', 'Child Welfare',
    'Women Empowerment', 'Animal Welfare', 'Elderly Care',
    'Disability Support', 'Poverty Alleviation', 'Disaster Relief'
  ];
  
  final List<String> _languageOptions = [
    'English', 'Hindi', 'Bengali', 'Telugu', 'Marathi',
    'Tamil', 'Gujarati', 'Kannada', 'Malayalam', 'Punjabi', 'Other'
  ];
  
  final List<String> _idTypes = [
    'Aadhar Card', 'PAN Card', 'Voter ID', 'Driving License', 'Passport'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      
      // Try to load existing volunteer profile
      final doc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['displayName'] ?? user.displayName ?? '';
          _contactController.text = data['phone'] ?? '';
          _locationController.text = data['location'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate basic info
      if (_nameController.text.isEmpty) {
        _showError('Please enter your name');
        return;
      }
      if (_contactController.text.isEmpty) {
        _showError('Please enter your contact number');
        return;
      }
      if (_locationController.text.isEmpty) {
        _showError('Please enter your location');
        return;
      }
    }
    
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickIdDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _idDocument = File(image.path);
        });
      }
    } catch (e) {
      _showError('Error picking document: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 4380)), // 12 years ago
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _submitRegistration() async {
    // Validate skills page
    if (_selectedSkills.isEmpty) {
      _showError('Please select at least one skill');
      return;
    }
    if (_selectedCauses.isEmpty) {
      _showError('Please select at least one cause');
      return;
    }
    if (_emergencyContactController.text.isEmpty) {
      _showError('Please enter emergency contact');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Please login to continue');
        return;
      }

      String? idDocumentUrl;
      
      // Upload ID document if selected
      if (_idDocument != null && _selectedIdType.isNotEmpty) {
        final fileName = 'volunteer_ids/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(_idDocument!);
        idDocumentUrl = await ref.getDownloadURL();
      }

      // Update volunteer profile
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .set({
        'displayName': _nameController.text.trim(),
        'email': user.email,
        'phone': _contactController.text.trim(),
        'location': _locationController.text.trim(),
        'dob': _dobController.text,
        'gender': _selectedGender,
        'preferredType': _preferredType,
        'availability': _availability,
        'commitment': _commitment,
        'skills': _selectedSkills,
        'causes': _selectedCauses,
        'languages': _selectedLanguages,
        'idType': _selectedIdType,
        'idDocumentUrl': idDocumentUrl,
        'emergencyContact': _emergencyContactController.text.trim(),
        'registrationComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Fetch volunteer photo from volunteers collection
      String? volunteerPhotoUrl = user.photoURL;
      try {
        final volunteerDoc = await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(user.uid)
            .get();
        if (volunteerDoc.exists) {
          final data = volunteerDoc.data();
          volunteerPhotoUrl = data?['photoUrl'] ?? user.photoURL;
        }
      } catch (e) {
        debugPrint('Error fetching volunteer photo: $e');
      }

      // Send volunteer request to NGO
      await FirebaseFirestore.instance.collection('volunteer_requests').add({
        'ngoId': widget.ngoId,
        'ngoName': widget.ngoName,
        'volunteerId': user.uid,
        'volunteerName': _nameController.text.trim(),
        'volunteerEmail': user.email,
        'volunteerPhotoUrl': volunteerPhotoUrl,
        'volunteeringFor': _selectedCauses.join(', '),
        'location': _locationController.text.trim(),
        'experience': _selectedSkills.join(', '),
        'preferredType': _preferredType,
        'availability': _availability,
        'commitment': _commitment,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration submitted successfully! Waiting for NGO approval.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to Volunteer Opportunities screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VolunteerOpportunitiesScreen(),
          ),
        );
      }
    } catch (e) {
      _showError('Error submitting registration: $e');
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
          'Register as Volunteer',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Page indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildPageIndicator(0, 'Basic Information'),
                const SizedBox(width: 8),
                _buildPageIndicator(1, 'Skill & Interest'),
              ],
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildBasicInfoPage(),
                _buildSkillsInterestPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int page, String title) {
    final isActive = _currentPage >= page;
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? primary : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Name
          _buildLabel('Name'),
          _buildTextField(_nameController, 'Enter your full name'),
          const SizedBox(height: 16),
          
          // DOB
          _buildLabel('DOB'),
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: _buildTextField(_dobController, 'DD/MM/YYYY', 
                suffixIcon: Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          
          // Gender
          _buildLabel('Gender'),
          _buildDropdownField(
            _selectedGender.isEmpty ? null : _selectedGender,
            ['Male', 'Female', 'Other'],
            'Select Gender',
            (value) => setState(() => _selectedGender = value ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Contact Number
          _buildLabel('Contact Number'),
          _buildTextField(_contactController, 'Enter your contact number',
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          
          // Location
          _buildLabel('Location'),
          _buildTextField(_locationController, 'City, State, Pincode'),
          const SizedBox(height: 8),
          Center(child: Text('Or', style: TextStyle(color: Colors.grey.shade500))),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Enable location
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location feature coming soon!')),
                );
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text('Enable location', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Availability Section
          Text(
            'Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Preferred Volunteer Type
          _buildLabel('Preferred Volunteer Type'),
          _buildRadioGroup(
            ['Online', 'Offline', 'Hybrid'],
            _preferredType,
            (value) => setState(() => _preferredType = value),
          ),
          const SizedBox(height: 16),
          
          // Availability
          _buildLabel('Availability'),
          _buildRadioGroup(
            ['Weekdays', 'Weekends', 'Specific Hours'],
            _availability,
            (value) => setState(() => _availability = value),
          ),
          const SizedBox(height: 16),
          
          // Commitment
          _buildLabel('Commitment'),
          _buildRadioGroup(
            ['One time', 'Short term', 'Long term'],
            _commitment,
            (value) => setState(() => _commitment = value),
          ),
          const SizedBox(height: 24),
          
          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillsInterestPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill & Interest',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Relevant Skills
          _buildLabel('Relevant Skills'),
          _buildMultiSelectDropdown(
            _selectedSkills,
            _skillOptions,
            'Select skills',
            (selected) => setState(() => _selectedSkills = selected),
          ),
          const SizedBox(height: 16),
          
          // Causes You Care About
          _buildLabel('Causes You care about'),
          _buildMultiSelectDropdown(
            _selectedCauses,
            _causeOptions,
            'Select causes',
            (selected) => setState(() => _selectedCauses = selected),
          ),
          const SizedBox(height: 16),
          
          // Languages Spoken
          _buildLabel('Language spoken'),
          _buildMultiSelectDropdown(
            _selectedLanguages,
            _languageOptions,
            'Select languages',
            (selected) => setState(() => _selectedLanguages = selected),
          ),
          const SizedBox(height: 24),
          
          // Verification Section
          Text(
            'Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Your ID
          _buildLabel('Your ID'),
          _buildDropdownField(
            _selectedIdType.isEmpty ? null : _selectedIdType,
            _idTypes,
            'Select ID type',
            (value) => setState(() => _selectedIdType = value ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Upload File
          GestureDetector(
            onTap: _pickIdDocument,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _idDocument != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_idDocument!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _idDocument = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Upload File',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Drag and drop file here',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Emergency Contact
          _buildLabel('Emergency Contact'),
          _buildTextField(_emergencyContactController, 'Enter emergency contact number',
            keyboardType: TextInputType.phone),
          const SizedBox(height: 32),
          
          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Back Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _previousPage,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, 
      {IconData? suffixIcon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        suffixIcon: suffixIcon != null 
            ? Icon(suffixIcon, color: Colors.grey.shade400)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField(String? value, List<String> items, String hint, 
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint, style: TextStyle(color: Colors.grey.shade400)),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioGroup(List<String> options, String selected, 
      void Function(String) onChanged) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primary : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectDropdown(List<String> selected, List<String> options,
      String hint, void Function(List<String>) onChanged) {
    return GestureDetector(
      onTap: () {
        _showMultiSelectDialog(selected, options, hint, onChanged);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: selected.isEmpty
                  ? Text(
                      '— Select —',
                      style: TextStyle(color: Colors.grey.shade400),
                    )
                  : Text(
                      selected.join(', '),
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showMultiSelectDialog(List<String> selected, List<String> options,
      String title, void Function(List<String>) onChanged) {
    List<String> tempSelected = List.from(selected);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title, style: TextStyle(color: primary)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = tempSelected.contains(option);
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  activeColor: primary,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        tempSelected.add(option);
                      } else {
                        tempSelected.remove(option);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                onChanged(tempSelected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
