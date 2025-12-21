import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class DocumentManagementModal extends StatefulWidget {
  final String ngoId;
  final dynamic ngoData;
  final VoidCallback onDocumentsUpdated;
  const DocumentManagementModal({Key? key, required this.ngoId, required this.ngoData, required this.onDocumentsUpdated}) : super(key: key);
  @override
  State<DocumentManagementModal> createState() => DocumentManagementModalState();
}

class DocumentManagementModalState extends State<DocumentManagementModal> {
  bool isUploading = false;
  String? uploadingDocType;

  final List<Map<String, String>> docs = [
    {'name': 'Registration Certificate', 'key': 'registrationCertUrl'},
    {'name': 'PAN Card', 'key': 'panCardUrl'},
    {'name': '12A/80G Certificate', 'key': 'certificate12A80GUrl'},
    {'name': 'ID Proof', 'key': 'idProofUrl'},
    {'name': 'Past Work Proof', 'key': 'pastWorkProofUrl'},
  ];

  Map<String, dynamic> get ngoDataMap {
    if (widget.ngoData is Map<String, dynamic>) return widget.ngoData as Map<String, dynamic>;
    try {
      if (widget.ngoData != null) {
        final dynamic d = widget.ngoData;
        final toJson = d.toJson;
        if (toJson is Function) {
          final result = toJson();
          if (result is Map<String, dynamic>) return result;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> _pickAndUpload(String docKey, String docName) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() { isUploading = true; uploadingDocType = docKey; });
    try {
      final ref = FirebaseStorage.instance.ref().child('ngo_docs/${widget.ngoId}_${docKey}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('ngo_registrations').doc(widget.ngoId).update({
        docKey: url,
        docKey.replaceAll('Url', 'Uploaded'): true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      widget.onDocumentsUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$docName uploaded successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading $docName: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() { isUploading = false; uploadingDocType = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manage Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...docs.map((doc) {
            final uploaded = ngoDataMap[doc['key']!.replaceAll('Url', 'Uploaded')] == true;
            final url = ngoDataMap[doc['key']!];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(uploaded ? Icons.check_circle : Icons.pending, color: uploaded ? Colors.green : Colors.orange),
                title: Text(doc['name']!),
                subtitle: uploaded && url != null && url.isNotEmpty ? Text('Uploaded') : Text('Not uploaded'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (uploaded && url != null && url.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () async {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open document URL')));
                          }
                        },
                      ),
                    IconButton(
                      icon: isUploading && uploadingDocType == doc['key'] ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, color: Colors.orange),
                      onPressed: isUploading ? null : () => _pickAndUpload(doc['key']!, doc['name']!),
                      tooltip: uploaded ? 'Replace' : 'Upload',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
