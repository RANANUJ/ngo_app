import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';

class ReviewNgoScreen extends StatefulWidget {
  final NgoRegistrationRequest request;
  const ReviewNgoScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<ReviewNgoScreen> createState() => _ReviewNgoScreenState();
}

class _ReviewNgoScreenState extends State<ReviewNgoScreen> {
  int _currentStep = 0;
  final NgoRegistrationService _service = NgoRegistrationService();
  bool _isLoading = false;
  static const Color primaryColor = Color(0xFF0099B8);

  // Form controllers for Step 1
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  // Checklist for Step 3
  bool _certVerified = false;
  bool _panVerified = false;
  bool _addressVerified = false;
  bool _bylawsVerified = false;
  bool _imageVerified = false;
  bool _othersVerified = false;

  // Notes for Step 4
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.request.ngoName);
    _emailController = TextEditingController(text: widget.request.email);
    _phoneController = TextEditingController(text: widget.request.officialPhone);
    _websiteController = TextEditingController(text: widget.request.websiteLink);
    _addressController = TextEditingController(text: widget.request.headOfficeAddress);

    // Initialize checklist based on uploaded documents
    _certVerified = widget.request.registrationCertUploaded;
    _panVerified = widget.request.panCardUploaded;
    _addressVerified = widget.request.idProofUploaded;
    _imageVerified = widget.request.profileImageUrl != null && widget.request.profileImageUrl!.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitVerification() async {
    setState(() => _isLoading = true);

    try {
      // 1. Update NGO detailed info if modified
      await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.request.id)
          .update({
        'ngoName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'officialPhone': _phoneController.text.trim(),
        'websiteLink': _websiteController.text.trim(),
        'headOfficeAddress': _addressController.text.trim(),
        'verificationNotes': _notesController.text.trim(),
        'checklist': {
          'registrationCert': _certVerified,
          'panCard': _panVerified,
          'addressProof': _addressVerified,
          'bylaws': _bylawsVerified,
          'profileImage': _imageVerified,
          'others': _othersVerified,
        }
      });

      // 2. Perform final approval
      final success = await _service.approveRegistration(widget.request.id);

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NGO Verified and Approved Successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Approval service failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during verification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify NGO',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              elevation: 0,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _submitVerification();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: details.onStepCancel,
                            child: const Text('Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: details.onStepContinue,
                          child: Text(
                            _currentStep == 3 ? 'Approve & Verify' : 'Next',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.editing,
                  title: const Text('Info', style: TextStyle(fontSize: 12)),
                  content: _buildInfoStep(),
                ),
                Step(
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.editing,
                  title: const Text('Docs', style: TextStyle(fontSize: 12)),
                  content: _buildDocsStep(),
                ),
                Step(
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.editing,
                  title: const Text('Verify', style: TextStyle(fontSize: 12)),
                  content: _buildVerifyStep(),
                ),
                Step(
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.editing,
                  title: const Text('Finalize', style: TextStyle(fontSize: 12)),
                  content: _buildFinalizeStep(),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildTextField('Organization Name', _nameController),
        _buildTextField('Email Address', _emailController, keyboardType: TextInputType.emailAddress),
        _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
        _buildTextField('Website Link', _websiteController),
        _buildTextField('Physical Address', _addressController, maxLines: 2),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Review',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildDocStatusCard('Registration Certificate', widget.request.registrationCertUploaded),
        _buildDocStatusCard('PAN Card', widget.request.panCardUploaded),
        _buildDocStatusCard('Address Proof (ID Proof)', widget.request.idProofUploaded),
        _buildDocStatusCard('Bylaws / Memorandum of Association', widget.request.certificate12A80GUploaded),
      ],
    );
  }

  Widget _buildDocStatusCard(String label, bool isUploaded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: isUploaded ? Colors.green : Colors.grey,
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        trailing: Text(
          isUploaded ? 'UPLOADED' : 'MISSING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isUploaded ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Checklist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildChecklistTile('Registration Certificate Valid', _certVerified, (val) => setState(() => _certVerified = val ?? false)),
        _buildChecklistTile('PAN Card Details Authentic', _panVerified, (val) => setState(() => _panVerified = val ?? false)),
        _buildChecklistTile('Address Proof Verified', _addressVerified, (val) => setState(() => _addressVerified = val ?? false)),
        _buildChecklistTile('Bylaws / MoA Audited', _bylawsVerified, (val) => setState(() => _bylawsVerified = val ?? false)),
        _buildChecklistTile('Profile Images Genuine', _imageVerified, (val) => setState(() => _imageVerified = val ?? false)),
        _buildChecklistTile('Other Secondary Documents (Optional)', _othersVerified, (val) => setState(() => _othersVerified = val ?? false)),
      ],
    );
  }

  Widget _buildChecklistTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      activeColor: primaryColor,
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFinalizeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_outlined, size: 48, color: primaryColor),
        ),
        const SizedBox(height: 20),
        const Text(
          'Almost Done!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'You are about to verify and approve "${_nameController.text}". Please write any review notes below before finalizing.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Admin Review Notes (Optional)',
            hintText: 'e.g. Verified registration certificate and tax status.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
