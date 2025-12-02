import 'package:flutter/material.dart';
import 'constants.dart';
import 'widgets.dart';

/// Step 1: Basic NGO Information
class Step1BasicInfo extends StatelessWidget {
  final TextEditingController ngoNameController;
  final TextEditingController registrationNoController;
  final TextEditingController yearController;
  final String? selectedNgoType;
  final String? selectedCategory;
  final ValueChanged<String?> onNgoTypeChanged;
  final ValueChanged<String?> onCategoryChanged;

  const Step1BasicInfo({
    Key? key,
    required this.ngoNameController,
    required this.registrationNoController,
    required this.yearController,
    required this.selectedNgoType,
    required this.selectedCategory,
    required this.onNgoTypeChanged,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('NGO Name'),
        FormTextField(controller: ngoNameController),
        const SizedBox(height: 16),
        const FormLabel('Registration No/ Trust id'),
        FormTextField(controller: registrationNoController),
        const SizedBox(height: 16),
        const FormLabel('Type of NGO'),
        FormDropdown(
          value: selectedNgoType,
          hint: 'Please select',
          items: kNgoTypes,
          onChanged: onNgoTypeChanged,
        ),
        const SizedBox(height: 16),
        const FormLabel('NGO Category'),
        FormDropdown(
          value: selectedCategory,
          hint: '(Child, women)',
          items: kNgoCategories,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 16),
        const FormLabel('Year of establishment'),
        FormTextField(
          controller: yearController,
          hint: 'DD/MM/YYYY',
        ),
      ],
    );
  }
}

/// Step 2: Office Details
class Step2OfficeDetails extends StatelessWidget {
  final TextEditingController headOfficeController;
  final TextEditingController branchOfficeController;
  final TextEditingController phoneController;
  final TextEditingController websiteController;

  const Step2OfficeDetails({
    Key? key,
    required this.headOfficeController,
    required this.branchOfficeController,
    required this.phoneController,
    required this.websiteController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Head Office Address'),
        FormTextField(
          controller: headOfficeController,
          hint: 'City, State, pincode',
        ),
        const SizedBox(height: 16),
        const FormLabel('Branch office address'),
        FormTextField(controller: branchOfficeController),
        const SizedBox(height: 16),
        const FormLabel('Official phone no.'),
        FormTextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const FormLabel('Website Link / Social media Link'),
        FormTextField(
          controller: websiteController,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

/// Step 3: Contact Person Details
class Step3ContactPerson extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController designationController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? selectedIdProof;
  final ValueChanged<String?> onIdProofChanged;
  final bool idProofUploaded;
  final String? idProofFileName;
  final VoidCallback onIdProofUpload;

  const Step3ContactPerson({
    Key? key,
    required this.fullNameController,
    required this.designationController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.selectedIdProof,
    required this.onIdProofChanged,
    required this.idProofUploaded,
    this.idProofFileName,
    required this.onIdProofUpload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Full Name'),
        FormTextField(controller: fullNameController),
        const SizedBox(height: 16),
        const FormLabel('Designation'),
        FormTextField(controller: designationController),
        const SizedBox(height: 16),
        const FormLabel('Mobile No.'),
        FormTextField(
          controller: mobileController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        const FormLabel('Email id'),
        FormTextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const FormLabel('Password (Optional)'),
        FormPasswordField(
          controller: passwordController,
          hint: 'Enter password for login',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            'Leave empty to use default password: $kDefaultPassword',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const FormLabel('Upload / ID Proof'),
        FormDropdown(
          value: selectedIdProof,
          hint: 'Please select',
          items: kIdProofTypes,
          onChanged: onIdProofChanged,
        ),
        const SizedBox(height: 12),
        DocumentUploadBox(
          isUploaded: idProofUploaded,
          fileName: idProofFileName,
          onTap: onIdProofUpload,
        ),
      ],
    );
  }
}

/// Step 4: Document Upload
class Step4Documents extends StatelessWidget {
  final bool registrationCertUploaded;
  final String? registrationCertFileName;
  final VoidCallback onRegistrationCertUpload;
  
  final bool panCardUploaded;
  final String? panCardFileName;
  final VoidCallback onPanCardUpload;
  
  final bool certificate12A80GUploaded;
  final String? certificate12A80GFileName;
  final VoidCallback onCertificate12A80GUpload;
  
  final bool pastWorkProofUploaded;
  final String? pastWorkProofFileName;
  final VoidCallback onPastWorkProofUpload;

  const Step4Documents({
    Key? key,
    required this.registrationCertUploaded,
    this.registrationCertFileName,
    required this.onRegistrationCertUpload,
    required this.panCardUploaded,
    this.panCardFileName,
    required this.onPanCardUpload,
    required this.certificate12A80GUploaded,
    this.certificate12A80GFileName,
    required this.onCertificate12A80GUpload,
    required this.pastWorkProofUploaded,
    this.pastWorkProofFileName,
    required this.onPastWorkProofUpload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Registration certificate/ trust deed'),
        DocumentUploadBox(
          isUploaded: registrationCertUploaded,
          fileName: registrationCertFileName,
          onTap: onRegistrationCertUpload,
        ),
        const SizedBox(height: 20),
        const FormLabel('PAN Card of NGO'),
        DocumentUploadBox(
          isUploaded: panCardUploaded,
          fileName: panCardFileName,
          onTap: onPanCardUpload,
        ),
        const SizedBox(height: 20),
        const FormLabel('12A/80G certificate'),
        DocumentUploadBox(
          isUploaded: certificate12A80GUploaded,
          fileName: certificate12A80GFileName,
          onTap: onCertificate12A80GUpload,
        ),
        const SizedBox(height: 20),
        const FormLabel('Past work Proof (Photos, Reports)'),
        DocumentUploadBox(
          isUploaded: pastWorkProofUploaded,
          fileName: pastWorkProofFileName,
          onTap: onPastWorkProofUpload,
        ),
      ],
    );
  }
}

/// Step 5: Mission & Vision
class Step5MissionVision extends StatelessWidget {
  final TextEditingController missionController;
  final TextEditingController areaOfWorkController;
  final TextEditingController volunteersController;
  final TextEditingController achievementsController;

  const Step5MissionVision({
    Key? key,
    required this.missionController,
    required this.areaOfWorkController,
    required this.volunteersController,
    required this.achievementsController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormLabel('Mission & Vision'),
        FormTextField(
          controller: missionController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const FormLabel('Area of work'),
        FormTextField(controller: areaOfWorkController),
        const SizedBox(height: 16),
        const FormLabel('Active Volunteers / Members'),
        FormTextField(
          controller: volunteersController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const FormLabel('Previous campaigns / Achievements'),
        FormTextField(
          controller: achievementsController,
          maxLines: 3,
        ),
      ],
    );
  }
}
