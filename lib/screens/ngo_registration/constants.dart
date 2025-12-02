import 'package:flutter/material.dart';

/// Primary color used throughout the NGO registration flow
const Color kPrimaryColor = Color(0xFF0099B8);

/// Total number of steps in the registration process
const int kTotalSteps = 5;

/// Step titles for display purposes
const List<String> kStepTitles = [
  'Basic Info',
  'Office Details',
  'Contact Person',
  'Documents',
  'Mission & Vision',
];

/// Available NGO types
const List<String> kNgoTypes = [
  'Trust',
  'Society',
  'Section 8 Company',
  'Other',
];

/// Available NGO categories
const List<String> kNgoCategories = [
  'Child, Women',
  'Education',
  'Health',
  'Environment',
  'Elderly Care',
  'Other',
];

/// Available ID proof types
const List<String> kIdProofTypes = [
  'Aadhar Card',
  'PAN Card',
  'Voter ID',
  'Driving License',
  'Passport',
];

/// Allowed file extensions for document upload
const List<String> kAllowedFileExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// Default password if user doesn't provide one
const String kDefaultPassword = '123456';
