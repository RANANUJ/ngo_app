import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/features/storage/data/services/local_storage_service.dart';
import '../ngo/ngo_verification_status_screen.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';
import 'steps.dart';

/// NGO Registration Screen with multi-step form
/// 
/// This screen handles the complete NGO registration flow including:
/// - Step 1: Basic NGO Information
/// - Step 2: Office Details
/// - Step 3: Contact Person Details
/// - Step 4: Document Upload
/// - Step 5: Mission & Vision
class NgoRegistrationScreen extends StatefulWidget {
  const NgoRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<NgoRegistrationScreen> createState() => _NgoRegistrationScreenState();
}

class _NgoRegistrationScreenState extends State<NgoRegistrationScreen> {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// Current step index (0-based)
  int _currentStep = 0;

  /// Flag to track if verification is in progress
  bool _isVerifying = false;

  // ==========================================================================
  // FORM CONTROLLERS - Step 1: Basic Info
  // ==========================================================================
  final _ngoNameController = TextEditingController();
  final _registrationNoController = TextEditingController();
  final _yearController = TextEditingController();
  String? _selectedNgoType;
  String? _selectedCategory;

  // ==========================================================================
  // FORM CONTROLLERS - Step 2: Office Details
  // ==========================================================================
  final _headOfficeController = TextEditingController();
  final _branchOfficeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  // ==========================================================================
  // FORM CONTROLLERS - Step 3: Contact Person
  // ==========================================================================
  final _fullNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedIdProof;

  // ==========================================================================
  // FORM CONTROLLERS - Step 5: Mission & Vision
  // ==========================================================================
  final _missionController = TextEditingController();
  final _areaOfWorkController = TextEditingController();
  final _volunteersController = TextEditingController();
  final _achievementsController = TextEditingController();

  // ==========================================================================
  // DOCUMENT MANAGER
  // ==========================================================================
  final _documentsManager = DocumentsManager();

  // ==========================================================================
  // LIFECYCLE METHODS
  // ==========================================================================

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Dispose all text editing controllers
  void _disposeControllers() {
    // Step 1
    _ngoNameController.dispose();
    _registrationNoController.dispose();
    _yearController.dispose();
    // Step 2
    _headOfficeController.dispose();
    _branchOfficeController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    // Step 3
    _fullNameController.dispose();
    _designationController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Step 5
    _missionController.dispose();
    _areaOfWorkController.dispose();
    _volunteersController.dispose();
    _achievementsController.dispose();
  }

  // ==========================================================================
  // NAVIGATION METHODS
  // ==========================================================================

  /// Move to next step or submit if on last step
  void _nextStep() {
    if (_currentStep < kTotalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submitAndVerify();
    }
  }

  /// Move to previous step or exit if on first step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // ==========================================================================
  // DOCUMENT HANDLING METHODS
  // ==========================================================================

  /// Pick a document file using file picker
  Future<void> _pickDocument(DocumentType type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedFileExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        setState(() {
          _documentsManager.selectFile(type, file, fileName);
        });

        _showSnackBar('File selected: $fileName', isSuccess: true);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      _showSnackBar('Error selecting file: $e', isSuccess: false);
    }
  }

  /// Upload a document to Firebase Storage
  Future<String?> _uploadDocument(File file, String fileName) async {
    try {
      final extension = '.${file.path.split('.').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('ngo_documents')
          .child('$fileName$extension');

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    }
  }

  /// Upload all selected documents to Firebase Storage
  Future<void> _uploadAllDocuments() async {
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    for (final type in DocumentType.values) {
      final file = _documentsManager.getFile(type);
      if (file != null) {
        final url = await _uploadDocument(file, '${type.storagePath}_$uniqueId');
        _documentsManager.setDocumentUrl(type, url);
      }
    }
  }

  // ==========================================================================
  // SUBMISSION METHODS
  // ==========================================================================

  /// Submit the registration form
  Future<void> _submitAndVerify() async {
    setState(() => _isVerifying = true);

    _showLoadingDialog();

    try {
      // Upload documents
      await _uploadAllDocuments();

      // Submit registration
      final registration = await _submitRegistration();
      debugPrint('=== REGISTRATION SUCCESS: ${registration.id} ===');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      setState(() => _isVerifying = false);

      // Save to local storage
      await LocalStorageService().savePendingRegistration(registration.id);
      debugPrint('=== SAVED TO LOCAL STORAGE ===');

      // Navigate to verification status
      _navigateToVerificationStatus(registration.id);
    } catch (e, stackTrace) {
      debugPrint('=== REGISTRATION ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) Navigator.pop(context);
      setState(() => _isVerifying = false);

      _showErrorDialog(e.toString());
    }
  }

  /// Submit registration data to Firestore
  Future<NgoRegistrationRequest> _submitRegistration() async {
    final registrationService = NgoRegistrationService();
    final uploadStatus = _documentsManager.getAllUploadStatus();
    final urls = _documentsManager.getAllUrls();

    debugPrint('=== SUBMITTING REGISTRATION ===');

    return registrationService.submitRegistration(
      // Step 1: Basic Info
      ngoName: _ngoNameController.text,
      registrationNo: _registrationNoController.text,
      ngoType: _selectedNgoType ?? '',
      category: _selectedCategory ?? '',
      yearOfEstablishment: _yearController.text,
      // Step 2: Office Details
      headOfficeAddress: _headOfficeController.text,
      branchOfficeAddress: _branchOfficeController.text,
      officialPhone: _phoneController.text,
      websiteLink: _websiteController.text,
      // Step 3: Contact Person
      contactPersonName: _fullNameController.text,
      designation: _designationController.text,
      mobileNo: _mobileController.text,
      email: _emailController.text,
      idProofType: _selectedIdProof ?? '',
      password: _passwordController.text.trim().isEmpty
          ? kDefaultPassword
          : _passwordController.text.trim(),
      // Step 4: Documents - Upload Status
      idProofUploaded: uploadStatus['idProofUploaded']!,
      registrationCertUploaded: uploadStatus['registrationCertUploaded']!,
      panCardUploaded: uploadStatus['panCardUploaded']!,
      certificate12A80GUploaded: uploadStatus['certificate12A80GUploaded']!,
      pastWorkProofUploaded: uploadStatus['pastWorkProofUploaded']!,
      // Step 4: Documents - URLs
      idProofUrl: urls['idProofUrl'],
      registrationCertUrl: urls['registrationCertUrl'],
      panCardUrl: urls['panCardUrl'],
      certificate12A80GUrl: urls['certificate12A80GUrl'],
      pastWorkProofUrl: urls['pastWorkProofUrl'],
      // Step 5: Mission & Vision
      missionVision: _missionController.text,
      areaOfWork: _areaOfWorkController.text,
      activeVolunteers: _volunteersController.text,
      achievements: _achievementsController.text,
    );
  }

  // ==========================================================================
  // DIALOG METHODS
  // ==========================================================================

  /// Show loading dialog during upload
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UploadingDialog(),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(
          'There was an error submitting your registration:\n\n$error\n\n'
          'Please check your internet connection and try again.',
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

  /// Show snack bar message
  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to verification status screen
  void _navigateToVerificationStatus(String registrationId) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => NgoVerificationStatusScreen(registrationId: registrationId),
      ),
      (route) => false,
    );
  }

  // ==========================================================================
  // BUILD METHODS
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          StepIndicator(currentStep: _currentStep, totalSteps: kTotalSteps),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavigationButton(),
        ],
      ),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
        onPressed: _previousStep,
      ),
      title: const Text(
        'Register Your NGO',
        style: TextStyle(
          color: kPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  /// Build navigation button (Next/Submit)
  Widget _buildNavigationButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            _currentStep == kTotalSteps - 1 ? 'SUBMIT' : 'Next',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the current step content
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1BasicInfo(
          ngoNameController: _ngoNameController,
          registrationNoController: _registrationNoController,
          yearController: _yearController,
          selectedNgoType: _selectedNgoType,
          selectedCategory: _selectedCategory,
          onNgoTypeChanged: (v) => setState(() => _selectedNgoType = v),
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
        );
      case 1:
        return Step2OfficeDetails(
          headOfficeController: _headOfficeController,
          branchOfficeController: _branchOfficeController,
          phoneController: _phoneController,
          websiteController: _websiteController,
        );
      case 2:
        return Step3ContactPerson(
          fullNameController: _fullNameController,
          designationController: _designationController,
          mobileController: _mobileController,
          emailController: _emailController,
          passwordController: _passwordController,
          selectedIdProof: _selectedIdProof,
          onIdProofChanged: (v) => setState(() => _selectedIdProof = v),
          idProofUploaded: _documentsManager.isDocumentSelected(DocumentType.idProof),
          idProofFileName: _documentsManager.getFileName(DocumentType.idProof),
          onIdProofUpload: () => _pickDocument(DocumentType.idProof),
        );
      case 3:
        return Step4Documents(
          registrationCertUploaded: _documentsManager.isDocumentSelected(DocumentType.registrationCert),
          registrationCertFileName: _documentsManager.getFileName(DocumentType.registrationCert),
          onRegistrationCertUpload: () => _pickDocument(DocumentType.registrationCert),
          panCardUploaded: _documentsManager.isDocumentSelected(DocumentType.panCard),
          panCardFileName: _documentsManager.getFileName(DocumentType.panCard),
          onPanCardUpload: () => _pickDocument(DocumentType.panCard),
          certificate12A80GUploaded: _documentsManager.isDocumentSelected(DocumentType.certificate12A80G),
          certificate12A80GFileName: _documentsManager.getFileName(DocumentType.certificate12A80G),
          onCertificate12A80GUpload: () => _pickDocument(DocumentType.certificate12A80G),
          pastWorkProofUploaded: _documentsManager.isDocumentSelected(DocumentType.pastWorkProof),
          pastWorkProofFileName: _documentsManager.getFileName(DocumentType.pastWorkProof),
          onPastWorkProofUpload: () => _pickDocument(DocumentType.pastWorkProof),
        );
      case 4:
        return Step5MissionVision(
          missionController: _missionController,
          areaOfWorkController: _areaOfWorkController,
          volunteersController: _volunteersController,
          achievementsController: _achievementsController,
        );
      default:
        return Step1BasicInfo(
          ngoNameController: _ngoNameController,
          registrationNoController: _registrationNoController,
          yearController: _yearController,
          selectedNgoType: _selectedNgoType,
          selectedCategory: _selectedCategory,
          onNgoTypeChanged: (v) => setState(() => _selectedNgoType = v),
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
        );
    }
  }
}
