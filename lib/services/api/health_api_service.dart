import 'dart:async';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// service for handling health-related API calls
class HealthApiService {
  final ApiClient _apiClient;

  static const String _baseUrl = 'http://localhost:8000/api';
HealthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient(baseUrl: _baseUrl);

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId/profile');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  ///pload health document to medical vault
  Future<Map<String, dynamic>> uploadDocument({
    required String userId,
    required String documentType,
    required String documentName,
    required DateTime documentDate,
    required List<int> fileBytes,
    String? description,
    List<String>? medicines,
  }) async {
    try {
//fill form from data
      final formData = FormData.fromMap({
        'document_type': documentType,
    'document_name': documentName,
    'document_date': documentDate.toIso8601String(),
        'description': description ?? '',
    'medicines': medicines ?? [],
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: documentName,
        ),
      });

  final response = await _apiClient.post(
    '/users/$userId/documents',
    data: formData,
    options: Options(
      contentType: 'multipart/form-data',
    ),
  );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// getting list of user's documents from medical vault
        Future<List<Map<String, dynamic>>> getUserDocuments(
      String userId, {
      String? documentType,
      DateTime? startDate,
      DateTime? endDate,
      int page = 1,
      int limit = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (documentType != null) {
        queryParams['document_type'] = documentType;
      }

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _apiClient.get(
        '/users/$userId/documents',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['documents'];
      return data.map((doc) => doc as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Gget doc details
  Future<Map<String, dynamic>> getDocumentDetails(
    String userId,
    String documentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/users/$userId/documents/$documentId',
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
// delete operations 
  Future<void> deleteDocument(String userId, String documentId) async {
    try {
      await _apiClient.delete('/users/$userId/documents/$documentId');
    } catch (e) {
      rethrow;
    }
  }

//  //updating the doc 
  Future<Map<String, dynamic>> updateDocumentMetadata(
    String userId,
    String documentId, {
    String? documentName,
    String? documentType,
    DateTime? documentDate,
    String? description,
    List<String>? medicines,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (documentName != null) data['document_name'] = documentName;
      if (documentType != null) data['document_type'] = documentType;
      if (documentDate != null) data['document_date'] = documentDate.toIso8601String();
      if (description != null) data['description'] = description;
      if (medicines != null) data['medicines'] = medicines;

      final response = await _apiClient.put(
        '/users/$userId/documents/$documentId',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
