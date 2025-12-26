
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String role; // 'student', 'writer', 'admin'
  final String? collegeId;
  final String? city;
  final String? phoneNumber;
  final String? location;
  final bool isWriterApproved;
  final double rating;
  final DateTime createdAt;
  final String? fcmToken;
  final List<String> sampleWorkUrls; // URLs of uploaded sample work (max 4)

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.role = 'student',
    this.collegeId,
    this.city,
    this.phoneNumber,
    this.location,
    this.isWriterApproved = false,
    this.rating = 0.0,
    required this.createdAt,
    this.fcmToken,
    this.sampleWorkUrls = const [],
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
      'phoneNumber': phoneNumber,
      'location': location,
      'isWriterApproved': isWriterApproved,
      'rating': rating,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'sampleWorkUrls': sampleWorkUrls,
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
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      isWriterApproved: map['isWriterApproved'] ?? false,
      rating: map['rating']?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      fcmToken: map['fcmToken'],
      sampleWorkUrls: List<String>.from(map['sampleWorkUrls'] ?? []),
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
         phoneNumber,
        location,
        isWriterApproved,
        rating,
        createdAt,
        fcmToken,
        sampleWorkUrls,
      ];
}
