import '../utils/constants.dart';
import 'firestore_service.dart';

class RewardService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> addPoints({
    required String userId,
    required int points,
    required String reason,
    String? itemId,
  }) async {
    await _firestoreService.addRewardPoints(
      uid: userId,
      points: points,
      reason: reason,
      itemId: itemId,
    );
  }

  Future<void> awardUploadPoints(String userId, String itemId) async {
    await addPoints(
      userId: userId,
      points: AppConstants.pointsUpload,
      reason: 'Item uploaded for donation',
      itemId: itemId,
    );
  }

  Future<void> awardDeliveryPoints(String userId, String itemId) async {
    await addPoints(
      userId: userId,
      points: AppConstants.pointsDelivered,
      reason: 'Item successfully delivered to NGO',
      itemId: itemId,
    );
  }

  Future<void> awardRepairPoints(String helperId, String itemId) async {
    await addPoints(
      userId: helperId,
      points: AppConstants.pointsRepaired,
      reason: 'Repair task completed successfully',
      itemId: itemId,
    );
  }

  Future<void> awardNgoAcceptancePoints(
      String ngoUserId, String itemId) async {
    await addPoints(
      userId: ngoUserId,
      points: AppConstants.pointsNgoAccepted,
      reason: 'Item request accepted by NGO',
      itemId: itemId,
    );
  }

  Stream<int> streamUserPoints(String userId) {
    return _firestoreService.streamUserPoints(userId);
  }

  Stream<List<Map<String, dynamic>>> streamRewardHistory(String userId) {
    return _firestoreService.streamRewardHistory(userId);
  }

  String getBadgeTier(int points) {
    if (points >= 1000) return 'platinum';
    if (points >= 500) return 'gold';
    if (points >= 200) return 'silver';
    if (points >= 50) return 'bronze';
    return 'newcomer';
  }
}
