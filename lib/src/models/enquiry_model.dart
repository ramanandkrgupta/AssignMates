import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String message;
  final String type; // 'whatsapp', 'call', 'text', 'preset'
  final DateTime createdAt;
  final bool isResolved;

  EnquiryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isResolved': isResolved,
    };
  }

  factory EnquiryModel.fromMap(Map<String, dynamic> map) {
    return EnquiryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      message: map['message'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isResolved: map['isResolved'] ?? false,
    );
  }
}
