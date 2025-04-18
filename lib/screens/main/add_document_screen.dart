import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:intl/intl.dart';
import '../../models/family_member.dart';
import '../../services/api/document_service.dart';
import 'package:collection/collection.dart';

class AddDocumentScreen extends StatefulWidget {
  final FamilyMember familyMember;

  const AddDocumentScreen({Key? key, required this.familyMember}) : super(key: key);

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _documentNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _documentType = 'Prescription';
  DateTime _documentDate = DateTime.now();
  File? _documentFile;
  bool _isUploading = false;
  String? _filePickError;
  final _formKey = GlobalKey<FormState>();
  final DocumentService _documentService = DocumentService.instance;

  final List<String> _documentTypes = [
    'Prescription',
    'Lab Report',
    'X-Ray',
    'MRI Scan',
    'CT Scan',
    'Ultrasound',
    'Vaccination Record',
    'Insurance Document',
    'Doctor Note',
    'Other'
  ];

  @override
  void dispose() {
    _documentNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanDocument() async {
    try {
      // Initialize the document scanner
      final scanner = FlutterDocScanner();

      // Start scanning - using the scanDocument method from flutter_doc_scanner
      final scannedDocs = await scanner.getScanDocuments() as List<Object?>;

      List<File> scannedFiles = [];
      for (var scannedDoc in scannedDocs) {
        scannedFiles.add(File(scannedDoc.toString()));
      }

      if (scannedFiles.isNotEmpty) {
        setState(() {
          _documentFile = scannedFiles.first;
          _filePickError = null;
        });
      } else {
        setState(() {
          _filePickError = 'No document scanned';
        });
      }
    } catch (e) {
      setState(() {
        _filePickError = 'Failed to scan document: $e';
      });
      debugPrint('Error scanning document: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _documentFile = File(result.files.single.path!);
          _filePickError = null;
        });
      }
    } catch (e) {
      setState(() {
        _filePickError = 'Failed to pick document: $e';
      });
      debugPrint('Error picking document: $e');
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _documentFile == null) {
      setState(() {
        if (_documentFile == null) {
          _filePickError = 'Please select a document file';
        }
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _documentService.uploadDocument(
        file: _documentFile!,
        documentName: _documentNameController.text,
        documentType: _documentType,
        documentDate: DateFormat('yyyy-MM-dd').format(_documentDate),
        familyMemberId: widget.familyMember.familyMemberId,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      if (result != null) {
        if (!mounted) return;
        // Document upload successful, return to previous screen
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _documentDate) {
      setState(() {
        _documentDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Document'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isUploading
          ? _buildUploadingIndicator()
          : _documentFile == null
              ? _buildDocumentPickerOptions()
              : _buildDocumentForm(),
    );
  }

  Widget _buildUploadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Uploading document...'),
        ],
      ),
    );
  }

  Widget _buildDocumentPickerOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add Document for ${widget.familyMember.fullName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Card(
            elevation: 4,
            child: InkWell(
              onTap: _scanDocument,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.document_scanner,
                        size: 40,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use your camera to scan a document',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        size: 40,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a file from your device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_filePickError != null) ...[
            const SizedBox(height: 16),
            Text(
              _filePickError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentForm() {
    String fileName = _documentFile?.path.split('/').last ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document preview or file name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isImageFile(_documentFile!.path))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _documentFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.description,
                            size: 60,
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _documentFile = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Document name field
            TextFormField(
              controller: _documentNameController,
              decoration: const InputDecoration(
                labelText: 'Document Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a document name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Document type dropdown
            DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(
                labelText: 'Document Type *',
                border: OutlineInputBorder(),
              ),
              items: _documentTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _documentType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Document date field
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Document Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('MMM d, yyyy').format(_documentDate),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a document date';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add notes or additional information',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Upload button
            ElevatedButton.icon(
              onPressed: _uploadDocument,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String path) {
    final lowerCasePath = path.toLowerCase();
    return lowerCasePath.endsWith('.jpg') || lowerCasePath.endsWith('.jpeg') || lowerCasePath.endsWith('.png');
  }
}
