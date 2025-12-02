import 'dart:io';

/// Enum representing different document types for NGO registration
enum DocumentType {
  idProof,
  registrationCert,
  panCard,
  certificate12A80G,
  pastWorkProof,
}

/// Extension to get display name for document types
extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.idProof:
        return 'ID Proof';
      case DocumentType.registrationCert:
        return 'Registration Certificate';
      case DocumentType.panCard:
        return 'PAN Card';
      case DocumentType.certificate12A80G:
        return '12A/80G Certificate';
      case DocumentType.pastWorkProof:
        return 'Past Work Proof';
    }
  }

  String get storagePath {
    switch (this) {
      case DocumentType.idProof:
        return 'id_proof';
      case DocumentType.registrationCert:
        return 'registration_cert';
      case DocumentType.panCard:
        return 'pan_card';
      case DocumentType.certificate12A80G:
        return 'certificate_12a80g';
      case DocumentType.pastWorkProof:
        return 'past_work_proof';
    }
  }
}

/// Model class to hold document upload information
class DocumentUpload {
  File? file;
  String? fileName;
  String? url;
  bool isUploaded;

  DocumentUpload({
    this.file,
    this.fileName,
    this.url,
    this.isUploaded = false,
  });

  /// Mark document as selected with file info
  void selectFile(File selectedFile, String name) {
    file = selectedFile;
    fileName = name;
    isUploaded = true;
  }

  /// Reset the document
  void reset() {
    file = null;
    fileName = null;
    url = null;
    isUploaded = false;
  }
}

/// Model class to manage all documents for registration
class DocumentsManager {
  final Map<DocumentType, DocumentUpload> _documents = {
    DocumentType.idProof: DocumentUpload(),
    DocumentType.registrationCert: DocumentUpload(),
    DocumentType.panCard: DocumentUpload(),
    DocumentType.certificate12A80G: DocumentUpload(),
    DocumentType.pastWorkProof: DocumentUpload(),
  };

  /// Get document by type
  DocumentUpload getDocument(DocumentType type) => _documents[type]!;

  /// Update document URL after upload
  void setDocumentUrl(DocumentType type, String? url) {
    _documents[type]!.url = url;
  }

  /// Check if a document has a file selected
  bool isDocumentSelected(DocumentType type) => _documents[type]!.isUploaded;

  /// Get file name for a document type
  String? getFileName(DocumentType type) => _documents[type]!.fileName;

  /// Get file for a document type
  File? getFile(DocumentType type) => _documents[type]!.file;

  /// Get URL for a document type
  String? getUrl(DocumentType type) => _documents[type]!.url;

  /// Select file for a document type
  void selectFile(DocumentType type, File file, String fileName) {
    _documents[type]!.selectFile(file, fileName);
  }

  /// Get all document URLs as a map
  Map<String, String?> getAllUrls() {
    return {
      'idProofUrl': getUrl(DocumentType.idProof),
      'registrationCertUrl': getUrl(DocumentType.registrationCert),
      'panCardUrl': getUrl(DocumentType.panCard),
      'certificate12A80GUrl': getUrl(DocumentType.certificate12A80G),
      'pastWorkProofUrl': getUrl(DocumentType.pastWorkProof),
    };
  }

  /// Get all upload status as a map
  Map<String, bool> getAllUploadStatus() {
    return {
      'idProofUploaded': isDocumentSelected(DocumentType.idProof),
      'registrationCertUploaded': isDocumentSelected(DocumentType.registrationCert),
      'panCardUploaded': isDocumentSelected(DocumentType.panCard),
      'certificate12A80GUploaded': isDocumentSelected(DocumentType.certificate12A80G),
      'pastWorkProofUploaded': isDocumentSelected(DocumentType.pastWorkProof),
    };
  }
}
