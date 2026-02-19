import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final bool status;
  final String type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: json['date'],
      status: json['status'],
      type: json['type']
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(String source) {
    final data = json.decode(source);
    return NotificationResponse(
      notifications: (data['notifications'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList(),
      unreadCount: data['unread_count'],
    );
  }
}