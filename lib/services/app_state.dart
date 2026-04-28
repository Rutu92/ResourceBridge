import '../models/resource_model.dart';

class AppState {
  static final List<ResourceModel> _items = [];

  static void submitToNGO(ResourceModel item) => _items.insert(0, item);

  static List<ResourceModel> get submittedItems => List.unmodifiable(_items);

  static void acceptItem(String itemId) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(status: 'matched', matchedNgoId: 'ngo_guest');
    }
  }
}