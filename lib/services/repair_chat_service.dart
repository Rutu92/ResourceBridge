import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class RepairChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chatRooms =>
      _firestore.collection('repair_chats');

  // ── Create or fetch chat room ─────────────────────────────────────────────
  // Idempotent: uses taskId as the doc ID so it is created only once.

  Future<RepairChatRoom> getOrCreateChatRoom({
    required String taskId,
    required String ngoId,
    required String helperId,
  }) async {
    final docRef = _chatRooms.doc(taskId);
    final doc = await docRef.get();

    if (doc.exists) {
      return RepairChatRoom.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    }

    final room = RepairChatRoom(
      chatRoomId: taskId,
      taskId: taskId,
      ngoId: ngoId,
      helperId: helperId,
      createdAt: DateTime.now(),
    );

    await docRef.set(room.toMap());
    return room;
  }

  // ── Send a message ────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderRole, // 'ngo' | 'helper'
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef =
        _chatRooms.doc(chatRoomId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update last message on the chat room doc
    batch.update(_chatRooms.doc(chatRoomId), {
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Stream messages ───────────────────────────────────────────────────────

  Stream<List<ChatMessage>> streamMessages(String chatRoomId) {
    return _chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Mark messages as read ─────────────────────────────────────────────────

  Future<void> markMessagesRead({
    required String chatRoomId,
    required String readerRole, // mark all messages NOT sent by this role as read
  }) async {
    final snap = await _chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderRole', isNotEqualTo: readerRole)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Unread count stream ───────────────────────────────────────────────────

  Stream<int> streamUnreadCount({
    required String chatRoomId,
    required String readerRole,
  }) {
    return _chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderRole', isNotEqualTo: readerRole)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}