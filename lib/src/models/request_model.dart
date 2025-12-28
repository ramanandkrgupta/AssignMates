import 'payment_model.dart';
import 'timeline_step.dart';

class RequestModel {
  final String id;
  final String studentId;
  final String instructions; // Replaces title/desc/subject
  final DateTime deadline;
  final double budget;
  final String status;
  final List<String> attachmentUrls;
  final Map<String, String> mediaUrls; // {type: url}, e.g. {'pdf': url, 'video': url}
  final String? voiceNoteUrl;
  final int pageCount;
  final String pageType; // 'A4' or 'EdSheet'
  final String urgency; // '1day' etc.
  
  // Refactored History & Payments
  final List<TimelineStep> timeline; // Replaces statusHistory
  final List<PaymentTransaction> payments;

  final double finalAmount;
  final String? assignedWriterId;
  final bool isPageCountVerified;
  final bool isLocationVerified;
  final DateTime createdAt;
  
  // Additional Fields
  final String paymentStatus; // 'unpaid', 'half_paid', 'fully_paid'
  final double paidAmount;
  final bool isHalfPayment; // If user chose half payment initially
  final List<String> verificationPhotos; // Photos uploaded by writer for review
  final String? cancellationReason;
  final String? estimatedDeliveryTime; // e.g. "Today 5 pm"
  final DateTime? deliveryCompletedAt;

  RequestModel({
    required this.id,
    required this.studentId,
    required this.instructions,
    required this.deadline,
    required this.budget,
    this.status = 'created',
    this.attachmentUrls = const [],
    this.mediaUrls = const {},
    this.voiceNoteUrl,
    this.pageCount = 0,
    this.pageType = 'A4',
    this.urgency = 'standard',
    this.timeline = const [],
    this.payments = const [],
    this.finalAmount = 0.0,
    this.assignedWriterId,
    this.isPageCountVerified = false,
    this.isLocationVerified = false,
    required this.createdAt,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.isHalfPayment = false,
    this.verificationPhotos = const [],
    this.cancellationReason,
    this.estimatedDeliveryTime,
    this.deliveryCompletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'instructions': instructions,
      'deadline': deadline.millisecondsSinceEpoch,
      'budget': budget,
      'status': status,
      'attachmentUrls': attachmentUrls,
      'mediaUrls': mediaUrls,
      'voiceNoteUrl': voiceNoteUrl,
      'pageCount': pageCount,
      'pageType': pageType,
      'urgency': urgency,
      'timeline': timeline.map((x) => x.toMap()).toList(),
      'payments': payments.map((x) => x.toMap()).toList(),
      'finalAmount': finalAmount,
      'assignedWriterId': assignedWriterId,
      'isPageCountVerified': isPageCountVerified,
      'isLocationVerified': isLocationVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'isHalfPayment': isHalfPayment,
      'verificationPhotos': verificationPhotos,
      'cancellationReason': cancellationReason,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'deliveryCompletedAt': deliveryCompletedAt?.millisecondsSinceEpoch,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      instructions: map['instructions'] ?? '',
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] ?? 0),
      budget: (map['budget'] ?? 0).toDouble(),
      status: map['status'] ?? 'created',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      mediaUrls: Map<String, String>.from(map['mediaUrls'] ?? {}),
      voiceNoteUrl: map['voiceNoteUrl'],
      pageCount: map['pageCount'] ?? 0,
      pageType: map['pageType'] ?? 'A4',
      urgency: map['urgency'] ?? 'standard',
      
      timeline: map['timeline'] != null 
          ? List<TimelineStep>.from(map['timeline']?.map((x) => TimelineStep.fromMap(x)))
          : (map['statusHistory'] != null 
              ? _convertLegacyStatusHistory(List<Map<String, dynamic>>.from(map['statusHistory'])) 
              : []),
      
      payments: map['payments'] != null
          ? List<PaymentTransaction>.from(map['payments']?.map((x) => PaymentTransaction.fromMap(x)))
          : [],

      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
      assignedWriterId: map['assignedWriterId'],
      isPageCountVerified: map['isPageCountVerified'] ?? false,
      isLocationVerified: map['isLocationVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      isHalfPayment: map['isHalfPayment'] ?? false,
      verificationPhotos: List<String>.from(map['verificationPhotos'] ?? []),
      cancellationReason: map['cancellationReason'],
      estimatedDeliveryTime: map['estimatedDeliveryTime'],
      deliveryCompletedAt: map['deliveryCompletedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deliveryCompletedAt']) : null,
    );
  }

  // Helper to migrate old data if needed
  static List<TimelineStep> _convertLegacyStatusHistory(List<Map<String, dynamic>> history) {
    return history.map((h) {
      return TimelineStep(
        status: h['status'] ?? 'unknown',
        title: 'Status Update: ${h['status']}',
        description: 'Legacy status update',
        timestamp: DateTime.fromMillisecondsSinceEpoch(h['timestamp'] ?? 0),
        isCompleted: true,
      );
    }).toList();
  }
}
