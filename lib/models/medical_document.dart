class MedicalDocument {
  final int id;
  final String documentName;
  final String documentType;
  final String documentDate;
  final String? description;
  final String? downloadUrl;
  final int? fileSize;
  final String createdAt;

  MedicalDocument({
    required this.id,
    required this.documentName,
    required this.documentType,
    required this.documentDate,
    this.description,
    this.downloadUrl,
    this.fileSize,
    required this.createdAt,
  });

  // Factory constructor to create a MedicalDocument from a JSON map
  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'],
      documentName: json['document_name'],
      documentType: json['document_type'],
      documentDate: json['document_date'],
      description: json['description'],
      downloadUrl: json['download_url'],
      fileSize: json['file_size'],
      createdAt: json['created_at'],
    );
  }

  // Get file size in a readable format (KB, MB)
  String get readableFileSize {
    if (fileSize == null) return 'Unknown size';

    if (fileSize! < 1024) {
      return '$fileSize bytes';
    } else if (fileSize! < 1024 * 1024) {
      double size = fileSize! / 1024;
      return '${size.toStringAsFixed(1)} KB';
    } else {
      double size = fileSize! / (1024 * 1024);
      return '${size.toStringAsFixed(1)} MB';
    }
  }

  // Get document type icon
  String get documentTypeIcon {
    switch (documentType.toLowerCase()) {
      case 'prescription':
        return '💊'; // Pill emoji
      case 'lab report':
        return '🔬'; // Microscope emoji
      case 'xray':
      case 'x-ray scan':
      case 'xray scan':
        return '🩻'; // X-ray emoji
      default:
        return '📄'; // Default document emoji
    }
  }
}
