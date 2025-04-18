import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../../models/medical_document.dart';
import '../../config/env_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class DocumentService {
  // Singleton pattern
  static final DocumentService _instance = DocumentService._internal();
  static DocumentService get instance => _instance;

  late final ApiClient _apiClient;

  DocumentService._internal() {
    _apiClient = ApiClient(
      requiresAuth: true,
    );
  }

  // Upload document - Simple direct upload to API
  Future<MedicalDocument?> uploadDocument({
    required File file,
    required String documentName,
    required String documentType,
    required String documentDate,
    required int familyMemberId,
    String? description,
  }) async {
    try {
      debugPrint('Starting document upload process');

      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).replaceAll('.', '');
      final contentType = _getContentType(fileExtension);

      // Create form data
      FormData formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        'document_name': documentName,
        'document_type': documentType,
        'document_date': documentDate,
        'family_member_id': familyMemberId.toString(),
      });

      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }

      debugPrint('Uploading document to server API');
      final response = await _apiClient.post(
        '/documents/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('Upload response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final documentId = response.data['document_id'];
        debugPrint('Document uploaded with ID: $documentId');
        // Fetch the document details
        return await getDocument(documentId);
      } else {
        debugPrint('Error uploading document: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception uploading document: $e');
      return null;
    }
  }

  // Get documents for a family member
  Future<List<MedicalDocument>> getFamilyMemberDocuments(int familyMemberId) async {
    try {
      final response = await _apiClient.get('/documents/family/$familyMemberId/documents');

      if (response.statusCode == 200) {
        final List<dynamic> documentsJson = response.data['documents'];
        return documentsJson.map((json) => MedicalDocument.fromJson(json)).toList();
      } else {
        debugPrint('Error fetching documents: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching documents: $e');
      return [];
    }
  }

  // Get a specific document
  Future<MedicalDocument?> getDocument(int documentId) async {
    try {
      final response = await _apiClient.get('/documents/documents/$documentId');

      if (response.statusCode == 200) {
        return MedicalDocument.fromJson(response.data);
      } else {
        debugPrint('Error fetching document: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching document: $e');
      return null;
    }
  }

  // Delete a document
  Future<bool> deleteDocument(int documentId) async {
    try {
      final response = await _apiClient.delete('/documents/documents/$documentId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Exception deleting document: $e');
      return false;
    }
  }

  // Helper method to determine content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
