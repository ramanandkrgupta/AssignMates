
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String role; // 'student', 'writer', 'admin'
  final String? collegeId;
  final String? phoneNumber;
  final Map<String, dynamic>? location; // {lat: double, lng: double, address: String}

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
      location: map['location'] != null ? Map<String, dynamic>.from(map['location']) : null,
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
         phoneNumber,
        location,
        isWriterApproved,
        rating,
        createdAt,
      ];
}
