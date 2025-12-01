import 'package:flutter/material.dart';
import '../services/ngo_registration_service.dart';
import '../services/local_storage_service.dart';
import 'ngo_verification_status_screen.dart';

class NgoRegistrationScreen extends StatefulWidget {
  const NgoRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<NgoRegistrationScreen> createState() => _NgoRegistrationScreenState();
}

class _NgoRegistrationScreenState extends State<NgoRegistrationScreen> {
  static const Color primary = Color(0xFF0099B8);
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Step 1 controllers
  final TextEditingController _ngoNameController = TextEditingController();
  final TextEditingController _registrationNoController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  String? _selectedNgoType;
  String? _selectedCategory;

  // Step 2 controllers
  final TextEditingController _headOfficeController = TextEditingController();
  final TextEditingController _branchOfficeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Step 3 controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedIdProof;
  bool _obscurePassword = true;

  // Step 5 controllers
  final TextEditingController _missionController = TextEditingController();
  final TextEditingController _areaOfWorkController = TextEditingController();
  final TextEditingController _volunteersController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();

  final List<String> _ngoTypes = ['Trust', 'Society', 'Section 8 Company', 'Other'];
  final List<String> _categories = ['Child, Women', 'Education', 'Health', 'Environment', 'Elderly Care', 'Other'];
  final List<String> _idProofs = ['Aadhar Card', 'PAN Card', 'Voter ID', 'Driving License', 'Passport'];

  // Document upload tracking
  bool _idProofUploaded = false;
  bool _registrationCertUploaded = false;
  bool _panCardUploaded = false;
  bool _certificate12A80GUploaded = false;
  bool _pastWorkProofUploaded = false;

  @override
  void dispose() {
    _ngoNameController.dispose();
    _registrationNoController.dispose();
    _yearController.dispose();
    _headOfficeController.dispose();
    _branchOfficeController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _fullNameController.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _missionController.dispose();
    _areaOfWorkController.dispose();
    _volunteersController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  bool _isVerifying = false;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Submit and verify
      _submitAndVerify();
    }
  }

  Future<void> _submitAndVerify() async {
    setState(() {
      _isVerifying = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: primary),
            const SizedBox(height: 20),
            const Text(
              'Submitting your registration...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your application',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Submit to registration service
      final registrationService = NgoRegistrationService();
      debugPrint('=== SUBMITTING REGISTRATION ===');
      final registration = await registrationService.submitRegistration(
        ngoName: _ngoNameController.text,
        registrationNo: _registrationNoController.text,
        ngoType: _selectedNgoType ?? '',
        category: _selectedCategory ?? '',
        yearOfEstablishment: _yearController.text,
        headOfficeAddress: _headOfficeController.text,
        branchOfficeAddress: _branchOfficeController.text,
        officialPhone: _phoneController.text,
        websiteLink: _websiteController.text,
        contactPersonName: _fullNameController.text,
        designation: _designationController.text,
        mobileNo: _mobileController.text,
        email: _emailController.text,
        idProofType: _selectedIdProof ?? '',
        missionVision: _missionController.text,
        areaOfWork: _areaOfWorkController.text,
        activeVolunteers: _volunteersController.text,
        achievements: _achievementsController.text,
        idProofUploaded: _idProofUploaded,
        registrationCertUploaded: _registrationCertUploaded,
        panCardUploaded: _panCardUploaded,
        certificate12A80GUploaded: _certificate12A80GUploaded,
        pastWorkProofUploaded: _pastWorkProofUploaded,
        password: _passwordController.text.trim().isEmpty ? '123456' : _passwordController.text.trim(),
      );
      debugPrint('=== REGISTRATION SUCCESS: ${registration.id} ===');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        _isVerifying = false;
      });

      // Save registration ID to local storage for persistence
      final localStorageService = LocalStorageService();
      await localStorageService.savePendingRegistration(registration.id);
      debugPrint('=== SAVED TO LOCAL STORAGE ===');

      // Navigate to verification status screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => NgoVerificationStatusScreen(
              registrationId: registration.id,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e, stackTrace) {
      debugPrint('=== REGISTRATION ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        _isVerifying = false;
      });

      // Show error dialog to user
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(
              'There was an error submitting your registration:\n\n$e\n\nPlease check your internet connection and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
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
          onPressed: _previousStep,
        ),
        title: Text(
          'Register Your NGO',
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
          // Step indicator
          _buildStepIndicator(),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          // Next/Submit button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'SUBMIT' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
          return Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent ? primary : Colors.white,
                  border: Border.all(
                    color: primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCompleted || isCurrent ? Colors.white : primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (index < _totalSteps - 1)
                Container(
                  width: 30,
                  height: 2,
                  color: isCompleted ? primary : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return _buildStep1();
    }
  }

  // Step 1: Basic NGO Info
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('NGO Name'),
        _buildTextField(_ngoNameController, ''),
        const SizedBox(height: 16),
        _buildLabel('Registration No/ Trust id'),
        _buildTextField(_registrationNoController, ''),
        const SizedBox(height: 16),
        _buildLabel('Type of NGO'),
        _buildDropdown(
          value: _selectedNgoType,
          hint: 'Please select',
          items: _ngoTypes,
          onChanged: (value) => setState(() => _selectedNgoType = value),
        ),
        const SizedBox(height: 16),
        _buildLabel('NGO Category'),
        _buildDropdown(
          value: _selectedCategory,
          hint: '(Child, women)',
          items: _categories,
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
        const SizedBox(height: 16),
        _buildLabel('Year of establishment'),
        _buildTextField(_yearController, 'DD/MM/YYYY'),
      ],
    );
  }

  // Step 2: Office Details
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Head Office Address'),
        _buildTextField(_headOfficeController, 'City, State, pincode'),
        const SizedBox(height: 16),
        _buildLabel('Branch office address'),
        _buildTextField(_branchOfficeController, ''),
        const SizedBox(height: 16),
        _buildLabel('Official phone no.'),
        _buildTextField(_phoneController, ''),
        const SizedBox(height: 16),
        _buildLabel('Website Link / Social media Link'),
        _buildTextField(_websiteController, ''),
      ],
    );
  }

  // Step 3: Contact Person Details
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        _buildTextField(_fullNameController, ''),
        const SizedBox(height: 16),
        _buildLabel('Designation'),
        _buildTextField(_designationController, ''),
        const SizedBox(height: 16),
        _buildLabel('Mobile No.'),
        _buildTextField(_mobileController, ''),
        const SizedBox(height: 16),
        _buildLabel('Email id'),
        _buildTextField(_emailController, ''),
        const SizedBox(height: 16),
        _buildLabel('Password (Optional)'),
        _buildPasswordField(),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            'Leave empty to use default password: 123456',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Upload / ID Proof'),
        _buildDropdown(
          value: _selectedIdProof,
          hint: 'Please select',
          items: _idProofs,
          onChanged: (value) => setState(() => _selectedIdProof = value),
        ),
        const SizedBox(height: 12),
        _buildUploadBox(
          isUploaded: _idProofUploaded,
          onUpload: () => setState(() => _idProofUploaded = true),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Enter password for login',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  // Step 4: Document Upload
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Registeration certificate/ trust deed'),
        _buildUploadBox(
          isUploaded: _registrationCertUploaded,
          onUpload: () => setState(() => _registrationCertUploaded = true),
        ),
        const SizedBox(height: 20),
        _buildLabel('PAN Card of NGO'),
        _buildUploadBox(
          isUploaded: _panCardUploaded,
          onUpload: () => setState(() => _panCardUploaded = true),
        ),
        const SizedBox(height: 20),
        _buildLabel('12A/80G certificate'),
        _buildUploadBox(
          isUploaded: _certificate12A80GUploaded,
          onUpload: () => setState(() => _certificate12A80GUploaded = true),
        ),
        const SizedBox(height: 20),
        _buildLabel('Past work Proof (Photos, Reports)'),
        _buildUploadBox(
          isUploaded: _pastWorkProofUploaded,
          onUpload: () => setState(() => _pastWorkProofUploaded = true),
        ),
      ],
    );
  }

  // Step 5: Mission & Vision
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mission & Vision'),
        _buildTextField(_missionController, '', maxLines: 3),
        const SizedBox(height: 16),
        _buildLabel('Area of work'),
        _buildTextField(_areaOfWorkController, ''),
        const SizedBox(height: 16),
        _buildLabel('Active Volunteers / Members'),
        _buildTextField(_volunteersController, ''),
        const SizedBox(height: 16),
        _buildLabel('Previous campaigns / Achievements'),
        _buildTextField(_achievementsController, '', maxLines: 3),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required bool isUploaded,
    required VoidCallback onUpload,
  }) {
    return GestureDetector(
      onTap: () {
        // Simulate file upload - in production, use file_picker package
        onUpload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isUploaded ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: isUploaded ? Colors.green : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: isUploaded ? Colors.green : primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded ? 'File Uploaded' : 'Upload File',
              style: TextStyle(
                color: isUploaded ? Colors.green.shade700 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isUploaded) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to select file',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
