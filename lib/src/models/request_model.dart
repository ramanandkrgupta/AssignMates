class RequestModel {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String subject;
  final DateTime deadline;
  final double budget;
  final String status; // 'open', 'assigned', 'completed'
  final List<String> attachmentUrls;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.subject,
    required this.deadline,
    required this.budget,
    this.status = 'open',
    this.attachmentUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'subject': subject,
      'deadline': deadline.millisecondsSinceEpoch,
      'budget': budget,
      'status': status,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      deadline: DateTime.fromMillisecondsSinceEpoch(map['deadline'] ?? 0),
      budget: (map['budget'] ?? 0).toDouble(),
      status: map['status'] ?? 'open',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
