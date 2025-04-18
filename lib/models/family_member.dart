import 'package:flutter/material.dart';

class FamilyMember {
  final int id; // User ID
  final int familyMemberId; // Relationship ID
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String relationship;
  final String? dateOfBirth;
  final String? gender;
  final bool isSelf;
  IconData avatar;

  FamilyMember({
    required this.id,
    required this.familyMemberId,
    required this.fullName,
    this.phoneNumber,
    this.email,
    required this.relationship,
    this.dateOfBirth,
    this.gender,
    this.isSelf = false,
    this.avatar = Icons.person,
  });

  // Calculate age based on date of birth
  int? get age {
    if (dateOfBirth == null) return null;

    final birthDate = DateTime.parse(dateOfBirth!);
    final today = DateTime.now();

    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Factory constructor to create a FamilyMember from a JSON map
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    // Determine avatar based on relationship and gender
    IconData avatar = Icons.person;

    final relationship = json['relationship'] as String;
    final isSelf = json['is_self'] == true;

    if (isSelf) {
      avatar = Icons.account_circle; // Different icon for self
    } else if (relationship.toLowerCase().contains('child')) {
      avatar = Icons.child_care;
    } else if (relationship.toLowerCase().contains('parent') ||
        relationship.toLowerCase().contains('father') ||
        relationship.toLowerCase().contains('mother')) {
      avatar = Icons.elderly;
    } else if (relationship.toLowerCase().contains('spouse') ||
        relationship.toLowerCase().contains('wife') ||
        relationship.toLowerCase().contains('husband')) {
      avatar = Icons.favorite;
    } else if (relationship.toLowerCase().contains('sibling') ||
        relationship.toLowerCase().contains('brother') ||
        relationship.toLowerCase().contains('sister')) {
      avatar = Icons.people;
    }

    return FamilyMember(
      id: json['id'],
      familyMemberId: json['family_member_id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      relationship: json['relationship'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      isSelf: json['is_self'] == true,
      avatar: avatar,
    );
  }

  // Convert the FamilyMember instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_member_id': familyMemberId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'relationship': relationship,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'is_self': isSelf,
    };
  }
}
