import '../utils/constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profileImageUrl;
  final int rewardPoints;
  final String location;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final DateTime createdAt;
  final Map<String, dynamic>? roleSpecificData;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.rewardPoints = 0,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.isVerified = false,
    required this.createdAt,
    this.roleSpecificData,
  });

  bool get isContributor => role == AppConstants.roleContributor;
  bool get isNGO => role == AppConstants.roleNGO;
  bool get isHelper => role == AppConstants.roleHelper;
  bool get isAdmin => role == AppConstants.roleAdmin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'rewardPoints': rewardPoints,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'roleSpecificData': roleSpecificData,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? AppConstants.roleContributor,
      profileImageUrl: map['profileImageUrl'],
      rewardPoints: map['rewardPoints'] ?? 0,
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      isVerified: map['isVerified'] ?? false,
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      roleSpecificData: map['roleSpecificData'],
    );
  }

  UserModel copyWith({
    String? name,
    String? profileImageUrl,
    int? rewardPoints,
    String? location,
    double? latitude,
    double? longitude,
    bool? isVerified,
    Map<String, dynamic>? roleSpecificData,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      role: role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      roleSpecificData: roleSpecificData ?? this.roleSpecificData,
    );
  }
}
