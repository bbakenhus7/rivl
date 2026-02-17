// models/charity_model.dart

import 'package:flutter/material.dart';

class CharityModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;

  const CharityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
    };
  }

  factory CharityModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    return availableCharities.firstWhere(
      (c) => c.id == id,
      orElse: () => CharityModel(
        id: id,
        name: map['name'] as String? ?? 'Unknown Charity',
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? '',
        icon: Icons.volunteer_activism,
      ),
    );
  }

  static const List<CharityModel> availableCharities = [
    CharityModel(
      id: 'st_jude',
      name: "St. Jude Children's Research Hospital",
      description: 'Leading the way the world understands, treats, and defeats childhood cancer.',
      category: 'Health',
      icon: Icons.local_hospital,
    ),
    CharityModel(
      id: 'wounded_warrior',
      name: 'Wounded Warrior Project',
      description: 'Supports veterans and service members who incurred physical or mental injuries.',
      category: 'Veterans',
      icon: Icons.military_tech,
    ),
    CharityModel(
      id: 'feeding_america',
      name: 'Feeding America',
      description: 'The largest hunger-relief organization in the United States.',
      category: 'Hunger Relief',
      icon: Icons.restaurant,
    ),
    CharityModel(
      id: 'aspca',
      name: 'ASPCA',
      description: 'Preventing cruelty to animals and providing rescue for those in need.',
      category: 'Animals',
      icon: Icons.pets,
    ),
    CharityModel(
      id: 'habitat_humanity',
      name: 'Habitat for Humanity',
      description: 'Helping families build and improve places to call home.',
      category: 'Housing',
      icon: Icons.home,
    ),
  ];
}
