
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String role; // 'student', 'writer', 'admin'
  final String? collegeId;
  final String? city;
  final bool isWriterApproved;
  final double rating;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.role = 'student',
    this.collegeId,
    this.city,
    this.isWriterApproved = false,
    this.rating = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'role': role,
      'collegeId': collegeId,
      'city': city,
      'isWriterApproved': isWriterApproved,
      'rating': rating,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      photoURL: map['photoURL'],
      role: map['role'] ?? 'student',
      collegeId: map['collegeId'],
      city: map['city'],
      isWriterApproved: map['isWriterApproved'] ?? false,
      rating: map['rating']?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        photoURL,
        role,
        collegeId,
        city,
        isWriterApproved,
        rating,
        createdAt,
      ];
}
