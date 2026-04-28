import '../models/resource_model.dart';

/// In-memory store for user-submitted donations.
/// No Firebase, no permissions needed.
class LocalSubmissionService {
  static final List<ResourceModel> _items = [];

  static void addItem(ResourceModel item) {
    _items.insert(0, item); // newest first
  }

  static List<ResourceModel> get allItems => List.unmodifiable(_items);

  static List<ResourceModel> get acceptedItems =>
      _items.where((i) => i.matchedNgoId != null).toList();

  static void acceptItem(String itemId, String ngoId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        status: 'matched',
        matchedNgoId: ngoId,
      );
    }
  }
}
