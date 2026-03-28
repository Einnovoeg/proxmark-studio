class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.detail,
    required this.timestamp,
  });

  final String title;
  final String detail;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      title: json['title'] as String? ?? 'Activity',
      detail: json['detail'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
