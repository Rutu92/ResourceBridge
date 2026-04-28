import '../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String description;
  final String itemName;
  final String category;
  final String condition;
  final String aiClassification;
  final String repairType;
  final String repairDescription;
  final String location;
  final double latitude;
  final double longitude;
  final String status;
  final String? matchedNgoId;
  final String? assignedHelperId;
  final String? repairTaskId;
  final int rewardPoints;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Legacy fields kept for backward compat with original app's Realtime DB data
  final String voiceNote;
  final String materialType;
  final String quantity;
  final double estimatedValue;

  ResourceModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.description,
    this.itemName = '',
    this.category = '',
    required this.condition,
    this.aiClassification = AppConstants.classUsable,
    this.repairType = 'none',
    this.repairDescription = '',
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.matchedNgoId,
    this.assignedHelperId,
    this.repairTaskId,
    this.rewardPoints = 0,
    required this.createdAt,
    this.updatedAt,
    this.voiceNote = '',
    this.materialType = '',
    this.quantity = '',
    this.estimatedValue = 0.0,
  });

  bool get isUsable => aiClassification == AppConstants.classUsable;
  bool get isRepairable => aiClassification == AppConstants.classRepairable;
  bool get needsRepair => condition == 'needs_repair' || isRepairable;
  bool get isCompleted => status == AppConstants.statusCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'description': description,
      'itemName': itemName,
      'category': category,
      'condition': condition,
      'aiClassification': aiClassification,
      'repairType': repairType,
      'repairDescription': repairDescription,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'matchedNgoId': matchedNgoId,
      'assignedHelperId': assignedHelperId,
      'repairTaskId': repairTaskId,
      'rewardPoints': rewardPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'voiceNote': voiceNote,
      'materialType': materialType,
      'quantity': quantity,
      'estimatedValue': estimatedValue,
    };
  }
factory ResourceModel.fromMap(Map<String, dynamic> map) {
  // Safely parse createdAt whether it comes back as a Timestamp or String
  DateTime parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  return ResourceModel(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    description: map['description'] ?? map['voiceNote'] ?? '',
    itemName: map['itemName'] ?? map['materialType'] ?? '',
    category: map['category'] ?? '',
    condition: map['condition'] ?? 'good',
    aiClassification: map['aiClassification'] ?? AppConstants.classUsable,
    repairType: map['repairType'] ?? 'none',
    repairDescription: map['repairDescription'] ?? '',
    location: map['location'] ?? '',
    latitude: (map['latitude'] ?? 0).toDouble(),
    longitude: (map['longitude'] ?? 0).toDouble(),
    status: map['status'] ?? AppConstants.statusPending,
    matchedNgoId: map['matchedNgoId'],
    assignedHelperId: map['assignedHelperId'],
    repairTaskId: map['repairTaskId'],
    rewardPoints: map['rewardPoints'] ?? 0,
    createdAt: parseDate(map['createdAt']),
    updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    voiceNote: map['voiceNote'] ?? '',
    materialType: map['materialType'] ?? '',
    quantity: map['quantity'] ?? '',
    estimatedValue: (map['estimatedValue'] ?? 0).toDouble(),
  );
}

  ResourceModel copyWith({
    String? status,
    String? matchedNgoId,
    String? assignedHelperId,
    String? repairTaskId,
    String? aiClassification,
    int? rewardPoints,
    DateTime? updatedAt,
  }) {
    return ResourceModel(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      description: description,
      itemName: itemName,
      category: category,
      condition: condition,
      aiClassification: aiClassification ?? this.aiClassification,
      repairType: repairType,
      repairDescription: repairDescription,
      location: location,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      matchedNgoId: matchedNgoId ?? this.matchedNgoId,
      assignedHelperId: assignedHelperId ?? this.assignedHelperId,
      repairTaskId: repairTaskId ?? this.repairTaskId,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      voiceNote: voiceNote,
      materialType: materialType,
      quantity: quantity,
      estimatedValue: estimatedValue,
    );
  }
}
