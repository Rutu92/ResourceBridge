import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resource_model.dart';
import '../models/ngo_model.dart';
import '../models/repair_task_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  String get userId => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _users =>
      _firestore.collection(AppConstants.colUsers);
  CollectionReference get _items =>
      _firestore.collection(AppConstants.colItems);
  CollectionReference get _ngos =>
      _firestore.collection(AppConstants.colNGOs);
  CollectionReference get _repairTasks =>
      _firestore.collection(AppConstants.colRepairTasks);
  CollectionReference get _rewards =>
      _firestore.collection(AppConstants.colRewards);
  CollectionReference get _notifications =>
      _firestore.collection(AppConstants.colNotifications);

  // ── USERS ─────────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.id).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users
        .doc(uid)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────

  Future<void> sendChatMessage({
    required String itemId,
    required String senderId,
    required String message,
    required String senderRole,
  }) async {
    await _firestore
        .collection('chats')
        .doc(itemId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamChatMessages(String itemId) {
    return _firestore
        .collection('chats')
        .doc(itemId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── ITEMS ─────────────────────────────────────────────────────────────────

  Future<String> saveResource(ResourceModel resource) async {
    final docRef = _items.doc();
    await docRef.set({
      ...resource.toMap(),
      'id': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _addTrackingEntry(
      itemId: docRef.id,
      status: AppConstants.statusPending,
      note: 'Item uploaded by contributor',
      updatedBy: resource.userId,
    );
    return docRef.id;
  }

  Future<ResourceModel?> getResourceById(String id) async {
    final doc = await _items.doc(id).get();
    if (!doc.exists) return null;
    return ResourceModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateResourceStatus({
    required String resourceId,
    required String status,
    String? matchedNgoId,
    String? assignedHelperId,
    String? repairTaskId,
    String? updatedBy,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (matchedNgoId != null) updates['matchedNgoId'] = matchedNgoId;
    if (assignedHelperId != null) updates['assignedHelperId'] = assignedHelperId;
    if (repairTaskId != null) updates['repairTaskId'] = repairTaskId;
    await _items.doc(resourceId).update(updates);
    await _addTrackingEntry(
      itemId: resourceId,
      status: status,
      note: note ?? _defaultTrackingNote(status),
      updatedBy: updatedBy ?? userId,
    );
  }

  Stream<List<ResourceModel>> streamResourcesByUser(String uid) {
    return _items.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final docs = snap.docs
          .map((d) => ResourceModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Stream<List<ResourceModel>> streamPendingResources() {
    return _items
        .where('status', isEqualTo: AppConstants.statusClassified)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => ResourceModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      final available = docs
          .where((r) =>
              r.matchedNgoId == null &&
              r.aiClassification != AppConstants.classUnsuitable)
          .toList();
      available.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return available;
    });
  }

  Stream<List<ResourceModel>> streamRepairableResources() {
    return _items
        .where('aiClassification', isEqualTo: AppConstants.classRepairable)
        .where('status', whereIn: [
          AppConstants.statusClassified,
          AppConstants.statusInRepair
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ResourceModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  /// All items matched to this NGO — used by header badge count
  Stream<List<ResourceModel>> streamNGOItems(String ngoId) {
    return _items
        .where('matchedNgoId', isEqualTo: ngoId)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => ResourceModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  /// Items accepted by NGO that are NOT yet in repair
  /// (status == matched, pickup_scheduled, repaired, delivered, completed
  ///  — anything that is NOT in_repair)
  Stream<List<ResourceModel>> streamNGOAcceptedItems(String ngoId) {
    return _items
        .where('matchedNgoId', isEqualTo: ngoId)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => ResourceModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      // "Accepted" tab: everything except items currently in_repair
      final accepted = docs
          .where((r) =>
              r.status != AppConstants.statusInRepair &&
              r.status != AppConstants.statusRepaired &&
              r.status != AppConstants.statusCompleted)
          .toList();
      accepted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return accepted;
    });
  }

  /// Items matched to this NGO that a helper has accepted (status == in_repair)
  Stream<List<ResourceModel>> streamNGOUnderRepairItems(String ngoId) {
    return _items
        .where('matchedNgoId', isEqualTo: ngoId)
        .where('status', isEqualTo: AppConstants.statusInRepair)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => ResourceModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Stream<List<ResourceModel>> streamAllItems() {
    return _items
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ResourceModel.fromMap(d.data() as Map<String, dynamic>))
            .toList());
  }

  // ── TRACKING ──────────────────────────────────────────────────────────────

  Future<void> _addTrackingEntry({
    required String itemId,
    required String status,
    required String updatedBy,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    await _items.doc(itemId).collection('tracking').add({
      'status': status,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'updatedBy': updatedBy,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTracking({
    required String itemId,
    required String status,
    String? note,
    double? lat,
    double? lng,
  }) async {
    await _addTrackingEntry(
      itemId: itemId,
      status: status,
      note: note,
      latitude: lat,
      longitude: lng,
      updatedBy: userId,
    );
  }

  Stream<List<Map<String, dynamic>>> streamItemTracking(String itemId) {
    return _items
        .doc(itemId)
        .collection('tracking')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── NGOs ──────────────────────────────────────────────────────────────────

  Future<String> saveNGO(NGOModel ngo) async {
    await _ngos
        .doc(ngo.id)
        .set({...ngo.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return ngo.id;
  }

  Future<NGOModel?> getNGOById(String id) async {
    final doc = await _ngos.doc(id).get();
    if (!doc.exists) return null;
    return NGOModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<List<NGOModel>> getActiveNGOs() async {
    final snap = await _ngos
        .where('isActive', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => NGOModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<NGOModel?> findMatchingNGO({
    required String category,
    required double itemLat,
    required double itemLng,
  }) async {
    final snap = await _ngos
        .where('isActive', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .where('acceptedCategories', arrayContains: category)
        .get();

    if (snap.docs.isEmpty) {
      final all = await getActiveNGOs();
      return all.isNotEmpty ? all.first : null;
    }

    final ngos = snap.docs
        .map((d) => NGOModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();
    ngos.sort((a, b) => a
        .distanceTo(itemLat, itemLng)
        .compareTo(b.distanceTo(itemLat, itemLng)));
    return ngos.first;
  }

  // ── REPAIR TASKS ──────────────────────────────────────────────────────────
/// Fetch the repair task linked to a specific item + NGO.
/// Used by the NGO dashboard to find the task before opening helper chat.
Future<RepairTaskModel?> getRepairTaskByItemAndNgo({
  required String itemId,
  required String ngoId,
}) async {
  final snap = await _repairTasks
      .where('itemId', isEqualTo: itemId)
      .where('ngoId', isEqualTo: ngoId)
      .limit(1)
      .get();

  if (snap.docs.isEmpty) return null;
  return RepairTaskModel.fromMap(
      snap.docs.first.data() as Map<String, dynamic>);
}
  Future<String> createRepairTask(RepairTaskModel task) async {
    final docRef = _repairTasks.doc();
    await docRef.set({
      ...task.toMap(),
      'id': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateRepairTask(RepairTaskModel task) async {
    await _repairTasks.doc(task.id).update({
      ...task.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tasks visible to ALL helpers — status is 'pending' (no helper assigned yet)
  Stream<List<RepairTaskModel>> streamPendingRepairTasks() {
    return _repairTasks
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .map((snap) {
      final tasks = snap.docs
          .map((d) =>
              RepairTaskModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  Stream<List<RepairTaskModel>> streamRepairTasksByHelper(String helperId) {
    return _repairTasks
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map((snap) {
      final tasks = snap.docs
          .map((d) =>
              RepairTaskModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  Future<List<RepairTaskModel>> getPendingRepairTasks() async {
    final snap = await _repairTasks
        .where('status', isEqualTo: AppConstants.statusPending)
        .get();
    return snap.docs
        .map((d) =>
            RepairTaskModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  // ── REWARDS ───────────────────────────────────────────────────────────────

  Future<void> addRewardPoints({
    required String uid,
    required int points,
    required String reason,
    String? itemId,
  }) async {
    await _users.doc(uid).update({
      'rewardPoints': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _rewards.doc(uid).collection('transactions').add({
      'points': points,
      'reason': reason,
      'itemId': itemId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> streamUserPoints(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc.data() as Map<String, dynamic>)['rewardPoints'] ?? 0;
    });
  }

  Stream<List<Map<String, dynamic>>> streamRewardHistory(String uid) {
    return _rewards
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? itemId,
  }) async {
    await _notifications.doc(toUserId).collection('messages').add({
      'title': title,
      'body': body,
      'type': type,
      'itemId': itemId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _notifications
        .doc(uid)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── ADMIN STATS ───────────────────────────────────────────────────────────

  Future<Map<String, int>> getPlatformStats() async {
    final results = await Future.wait([
      _items.count().get(),
      _items
          .where('status', isEqualTo: AppConstants.statusCompleted)
          .count()
          .get(),
      _items
          .where('aiClassification', isEqualTo: AppConstants.classRepairable)
          .count()
          .get(),
      _ngos.where('isActive', isEqualTo: true).count().get(),
    ]);
    return {
      'totalItems': results[0].count ?? 0,
      'completedItems': results[1].count ?? 0,
      'repairItems': results[2].count ?? 0,
      'activeNGOs': results[3].count ?? 0,
    };
  }

  String _defaultTrackingNote(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Item uploaded by contributor';
      case AppConstants.statusClassified:
        return 'Item classified by Gemini AI';
      case AppConstants.statusMatched:
        return 'Matched with NGO';
      case AppConstants.statusPickupScheduled:
        return 'Pickup scheduled';
      case AppConstants.statusInRepair:
        return 'Item accepted by helper — repair in progress';
      case AppConstants.statusRepaired:
        return 'Repair completed';
      case AppConstants.statusDelivered:
        return 'Item delivered to NGO';
      case AppConstants.statusCompleted:
        return 'Flow completed successfully';
      default:
        return 'Status updated';
    }
  }
}