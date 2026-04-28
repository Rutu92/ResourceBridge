import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class RepairTaskModel {
  final String id;
  final String itemId;
  final String itemName; // ← NEW: human-readable name of the item
  final String contributorId;
  final String? ngoId;
  final String? helperId;
  final String repairType;
  final String description;
  final String status;
  final String estimatedCost;
  final String? actualCost;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? helperNotes;
  final List<String> beforeImageUrls;
  final List<String> afterImageUrls;

  RepairTaskModel({
    required this.id,
    required this.itemId,
    this.itemName = '',
    required this.contributorId,
    this.ngoId,
    this.helperId,
    required this.repairType,
    required this.description,
    required this.status,
    required this.estimatedCost,
    this.actualCost,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.helperNotes,
    this.beforeImageUrls = const [],
    this.afterImageUrls = const [],
  });

  bool get isPending => status == AppConstants.statusPending;
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == AppConstants.statusInRepair;
  bool get isCompleted => status == AppConstants.statusCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'contributorId': contributorId,
      'ngoId': ngoId,
      'helperId': helperId,
      'repairType': repairType,
      'description': description,
      'status': status,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'helperNotes': helperNotes,
      'beforeImageUrls': beforeImageUrls,
      'afterImageUrls': afterImageUrls,
    };
  }

  factory RepairTaskModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RepairTaskModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      contributorId: map['contributorId'] ?? '',
      ngoId: map['ngoId'],
      helperId: map['helperId'],
      repairType: map['repairType'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? AppConstants.statusPending,
      estimatedCost: map['estimatedCost'] ?? '0',
      actualCost: map['actualCost'],
      createdAt: parseDate(map['createdAt']),
      assignedAt: parseDateNullable(map['assignedAt']),
      completedAt: parseDateNullable(map['completedAt']),
      helperNotes: map['helperNotes'],
      beforeImageUrls: List<String>.from(map['beforeImageUrls'] ?? []),
      afterImageUrls: List<String>.from(map['afterImageUrls'] ?? []),
    );
  }

  RepairTaskModel copyWith({
    String? itemName,
    String? ngoId,
    String? helperId,
    String? status,
    String? actualCost,
    DateTime? assignedAt,
    DateTime? completedAt,
    String? helperNotes,
    List<String>? afterImageUrls,
  }) {
    return RepairTaskModel(
      id: id,
      itemId: itemId,
      itemName: itemName ?? this.itemName,
      contributorId: contributorId,
      ngoId: ngoId ?? this.ngoId,
      helperId: helperId ?? this.helperId,
      repairType: repairType,
      description: description,
      status: status ?? this.status,
      estimatedCost: estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      createdAt: createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      helperNotes: helperNotes ?? this.helperNotes,
      beforeImageUrls: beforeImageUrls,
      afterImageUrls: afterImageUrls ?? this.afterImageUrls,
    );
  }
}