import '../core/json.dart';

class AppNotification {
  final int notificationID;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.notificationID,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    notificationID: json['notificationID'],
    title: json['title'],
    message: json['message'],
    createdAt: parseDateTime(json['createdAt']),
    isRead: json['isRead'],
  );
}
