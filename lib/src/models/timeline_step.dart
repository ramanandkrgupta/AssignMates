class TimelineStep {
  final String status; // 'created', 'assigned', 'payment_pending', etc.
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final Map<String, bool> notificationsSent; // {'student': true, 'admin': false}

  TimelineStep({
    required this.status,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = true,
    this.notificationsSent = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'title': title,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'notificationsSent': notificationsSent,
    };
  }

  factory TimelineStep.fromMap(Map<String, dynamic> map) {
    return TimelineStep(
      status: map['status'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isCompleted: map['isCompleted'] ?? true,
      notificationsSent: Map<String, bool>.from(map['notificationsSent'] ?? {}),
    );
  }
}
