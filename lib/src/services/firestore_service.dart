import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.read(firestoreProvider));
});

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> createRequest(RequestModel request) async {
    await _db.collection('requests').doc(request.id).set(request.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromMap(snapshot.data()!);
      }
      return null;
    });
  }
  Stream<List<RequestModel>> getStudentRequests(String studentId) {
    return _db
        .collection('requests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RequestModel.fromMap(doc.data())).toList();
    });
  }

  Stream<List<RequestModel>> getWriterRequestsStream(String writerId) {
    return _db
        .collection('requests')
        .where('assignedWriterId', isEqualTo: writerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RequestModel.fromMap(doc.data())).toList();
    });
  }

  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
  }
  Future<void> updateRequest(String requestId, Map<String, dynamic> data) async {
    await _db.collection('requests').doc(requestId).update(data);
  }
  Future<void> updateUserRole(String uid, String role) async {
    final data = <String, dynamic>{'role': role};
    if (role == 'writer') {
      data['isAvailable'] = true;
    }
    await _db.collection('users').doc(uid).update(data);
  }
  Future<void> updateRequestStatus(String requestId, String status, {Map<String, dynamic>? additionalData}) async {
    final data = <String, dynamic>{'status': status};
    if (additionalData != null) {
      data.addAll(additionalData);
    }
    await _db.collection('requests').doc(requestId).update(data);
  }

  Future<List<RequestModel>> getAllRequests() async {
     final snapshot = await _db.collection('requests').orderBy('createdAt', descending: true).get();
     return snapshot.docs.map((doc) => RequestModel.fromMap(doc.data())).toList();
  }

  Stream<List<RequestModel>> getAllRequestsStream() {
    return _db.collection('requests').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => RequestModel.fromMap(doc.data())).toList();
    });
  }

  Future<List<AppUser>> getAdmins() async {
    final snapshot = await _db.collection('users').where('role', isEqualTo: 'admin').get();
    return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
  }

  Stream<List<AppUser>> getWritersStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'writer')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateFcmToken(String uid, String? token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  // --- Notification Methods ---

  Future<void> createNotification(NotificationModel notification) async {
    await _db.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    // We listen for notifications where targetUserId is 'admin' or matches the specific user
    return _db
        .collection('notifications')
        .where('targetUserId', whereIn: [userId, 'admin'])
        .snapshots()
        .map((snapshot) {
      final notifs = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifs;
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }
}

