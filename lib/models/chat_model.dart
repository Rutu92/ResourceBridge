import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderRole; // 'ngo' | 'helper'
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTimestamp(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessage(
      messageId: docId,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? '',
      text: map['text'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class RepairChatRoom {
  final String chatRoomId;
  final String taskId;
  final String ngoId;
  final String helperId;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime? lastMessageTime;

  RepairChatRoom({
    required this.chatRoomId,
    required this.taskId,
    required this.ngoId,
    required this.helperId,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageTime,
  });

  factory RepairChatRoom.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTimestamp(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return RepairChatRoom(
      chatRoomId: docId,
      taskId: map['taskId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      helperId: map['helperId'] ?? '',
      createdAt: parseTimestamp(map['createdAt']),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? parseTimestamp(map['lastMessageTime'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'ngoId': ngoId,
      'helperId': helperId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
    };
  }
}