import '../../models/family_member.dart';
import 'api_client.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  static FamilyService get instance => _instance;

  final ApiClient _apiClient;

  FamilyService._internal() : _apiClient = ApiClient(requiresAuth: true);

  // Get all family members
  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      final response = await _apiClient.get('/family');

      final List<dynamic> data = response.data['family_members'];
      return data.map((json) => FamilyMember.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch family members: ${e.toString()}');
    }
  }

  // Get a specific family member by ID
  Future<FamilyMember> getFamilyMember(int familyMemberId) async {
    try {
      final response = await _apiClient.get('/family/$familyMemberId');

      return FamilyMember.fromJson(response.data['family_member']);
    } catch (e) {
      throw Exception('Failed to fetch family member: ${e.toString()}');
    }
  }

  // Add a new family member
  Future<FamilyMember> addFamilyMember({
    required String fullName,
    required String relationship,
    String? phoneNumber,
    String? email,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final data = {
        'full_name': fullName,
        'relationship': relationship,
      };

      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (email != null) data['email'] = email;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;

      final response = await _apiClient.post(
        '/family',
        data: data,
      );

      return FamilyMember.fromJson(response.data['family_member']);
    } catch (e) {
      throw Exception('Failed to add family member: ${e.toString()}');
    }
  }

  // Update a family member
  Future<FamilyMember> updateFamilyMember({
    required int familyMemberId,
    String? fullName,
    String? relationship,
    String? email,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (fullName != null) data['full_name'] = fullName;
      if (relationship != null) data['relationship'] = relationship;
      if (email != null) data['email'] = email;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;

      final response = await _apiClient.put(
        '/family/$familyMemberId',
        data: data,
      );

      return FamilyMember.fromJson(response.data['family_member']);
    } catch (e) {
      throw Exception('Failed to update family member: ${e.toString()}');
    }
  }

  // Delete a family member
  Future<void> deleteFamilyMember(int familyMemberId) async {
    try {
      await _apiClient.delete('/family/$familyMemberId');
    } catch (e) {
      throw Exception('Failed to delete family member: ${e.toString()}');
    }
  }
}
