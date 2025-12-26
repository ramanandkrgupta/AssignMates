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
  final List<Map<String, dynamic>> statusHistory; // [{status: 'created', timestamp: ...}]
  final double finalAmount;
  final String? assignedWriterId;
  final bool isPageCountVerified;
  final bool isLocationVerified;
  final DateTime createdAt;
  // New Fields for Detailed Flow
  final String paymentStatus; // 'unpaid', 'half_paid', 'fully_paid'
  final double paidAmount;
  final bool isHalfPayment; // If user chose half payment initially
  final List<String> verificationPhotos; // Photos uploaded by writer for review

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
    this.statusHistory = const [],
    this.finalAmount = 0.0,
    this.assignedWriterId,
    this.isPageCountVerified = false,
    this.isLocationVerified = false,
    required this.createdAt,
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.isHalfPayment = false,
    this.verificationPhotos = const [],
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
      'statusHistory': statusHistory,
      'finalAmount': finalAmount,
      'assignedWriterId': assignedWriterId,
      'isPageCountVerified': isPageCountVerified,
      'isLocationVerified': isLocationVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'isHalfPayment': isHalfPayment,
      'verificationPhotos': verificationPhotos,
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
       statusHistory: List<Map<String, dynamic>>.from(map['statusHistory'] ?? []),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
      assignedWriterId: map['assignedWriterId'],
      isPageCountVerified: map['isPageCountVerified'] ?? false,
      isLocationVerified: map['isLocationVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      isHalfPayment: map['isHalfPayment'] ?? false,
      verificationPhotos: List<String>.from(map['verificationPhotos'] ?? []),
    );
  }
}
