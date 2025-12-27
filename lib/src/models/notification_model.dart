import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String targetUserId; // 'admin' for all admins, or specific UID
  final String? senderId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String status; // 'pending' or 'sent'

  NotificationModel({
    required this.id,
    required this.targetUserId,
    this.senderId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetUserId': targetUserId,
      'senderId': senderId,
      'title': title,
      'body': body,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'status': status,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      senderId: map['senderId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isRead: map['isRead'] ?? false,
      status: map['status'] ?? 'pending',
    );
  }
}
