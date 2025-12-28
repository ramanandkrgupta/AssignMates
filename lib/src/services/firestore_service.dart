import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import '../models/pricing_model.dart';
import '../models/payment_model.dart';
import '../models/timeline_step.dart';

// ... (existing constants)

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

  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    final docRef = _db.collection('notifications').doc();
    final notification = NotificationModel(
      id: docRef.id,
      targetUserId: targetUserId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      status: 'pending',
      type: type,
      payload: payload,
    );
    await docRef.set(notification.toMap());
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

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // --- Pricing Methods ---

  Future<void> setPricing(PricingModel pricing) async {
    print('FirestoreService: Setting pricing for ${pricing.id} with data: ${pricing.toMap()}');
    // Use the pricing.id (which should be city name lowercased or unique id) as doc id
    await _db.collection('pricing').doc(pricing.id).set(pricing.toMap());
  }

  Future<PricingModel> getPricing(String city) async {
    try {
      // 1. Try case-insensitive match if possible, but for now exact match on field
      final snapshot = await _db.collection('pricing').where('city', isEqualTo: city).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return PricingModel.fromMap(snapshot.docs.first.data());
      }
      
      // 2. Fetch default
      final defaultSnapshot = await _db.collection('pricing').doc('default').get();
      if (defaultSnapshot.exists) {
        return PricingModel.fromMap(defaultSnapshot.data()!);
      }
    } catch (e) {
      // ignore
    }

    // 3. Code default
    return PricingModel.defaultPricing();
  }

  Stream<List<PricingModel>> getAllPricingStream() {
    print('FirestoreService: Listening to getAllPricingStream');
    return _db.collection('pricing').snapshots().map((snapshot) {
      print('FirestoreService: Pricing snapshot received. Docs: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) => PricingModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> deletePricing(String id) async {
    if (id == 'default') return; // Protect default
    await _db.collection('pricing').doc(id).delete();
  }

  // --- New Methods for Detailed Flow ---

  Future<void> addPayment(String requestId, PaymentTransaction payment) async {
    await _db.collection('requests').doc(requestId).update({
      'payments': FieldValue.arrayUnion([payment.toMap()]),
      'paymentStatus': payment.amount > 0 ? 'paid' : 'unpaid',
      'paidAmount': FieldValue.increment(payment.amount),
    });
  }

  Future<void> addTimelineStep(String requestId, TimelineStep step) async {
    await _db.collection('requests').doc(requestId).update({
      'timeline': FieldValue.arrayUnion([step.toMap()]),
      'status': step.status,
    });
  }
  
  Future<void> updateRequestStatusWithStep(String requestId, String status, TimelineStep step, {Map<String, dynamic>? additionalData}) async {
    final data = <String, dynamic>{
      'status': status,
      'timeline': FieldValue.arrayUnion([step.toMap()]),
    };
    if (additionalData != null) {
      data.addAll(additionalData);
    }
    await _db.collection('requests').doc(requestId).update(data);
  }
}

