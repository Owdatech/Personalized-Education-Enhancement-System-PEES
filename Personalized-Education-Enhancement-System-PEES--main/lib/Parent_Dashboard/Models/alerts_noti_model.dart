class AlertsNotificationModel {
  List<Alerts>? alerts;
  List<Notifications>? notifications;

  AlertsNotificationModel({this.alerts, this.notifications});

  AlertsNotificationModel.fromJson(Map<String, dynamic> json) {
    if (json['alerts'] != null) {
      alerts = <Alerts>[];
      json['alerts'].forEach((v) {
        alerts!.add(Alerts.fromJson(v));
      });
    }
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(Notifications.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (alerts != null) {
      data['alerts'] = alerts!.map((v) => v.toJson()).toList();
    }
    if (notifications != null) {
      data['notifications'] = notifications!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Alerts {
  String? aiGeneratedMessage;
  int? currentScore;
  String? date;
  String? isSeen;
  int? previousScore;
  String? studentId;
  String? studentName;
  String? typeOfAlert;
  String? alertId;
  String? id;

  Alerts(
      {this.aiGeneratedMessage,
      this.currentScore,
      this.date,
      this.isSeen,
      this.previousScore,
      this.studentId,
      this.studentName,
      this.typeOfAlert,
      this.alertId,
      this.id});

  Alerts.fromJson(Map<String, dynamic> json) {
    aiGeneratedMessage = json['ai_generated_message'];
    currentScore = json['current_score'];
    date = json['date'];
    isSeen = json['isSeen'];
    previousScore = json['previous_score'];
    studentId = json['student_id'];
    studentName = json['student_name'];
    typeOfAlert = json['type_of_alert'];
    alertId = json['alert_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ai_generated_message'] = aiGeneratedMessage;
    data['current_score'] = currentScore;
    data['date'] = date;
    data['isSeen'] = isSeen;
    data['previous_score'] = previousScore;
    data['student_id'] = studentId;
    data['student_name'] = studentName;
    data['type_of_alert'] = typeOfAlert;
    data['alert_id'] = alertId;
    data['id'] = id;
    return data;
  }
}

class Notifications {
  String? createdAt;
  String? description;
  String? id;
  String? receiverId;
  String? responseMessage;
  String? responseStatus;
  String? responseTimestamp;
  String? senderId;
  bool? status;
  String? title;
  String? type;
  String? receiverRole;
  String? senderRole;

  Notifications(
      {this.createdAt,
      this.description,
      this.id,
      this.receiverId,
      this.responseMessage,
      this.responseStatus,
      this.responseTimestamp,
      this.senderId,
      this.status,
      this.title,
      this.type,
      this.receiverRole,
      this.senderRole});

  Notifications.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    description = json['description'];
    id = json['id'];
    receiverId = json['receiver_id'];
    responseMessage = json['responseMessage'];
    responseStatus = json['responseStatus'];
    responseTimestamp = json['responseTimestamp'];
    senderId = json['sender_id'];
    status = json['status'];
    title = json['title'];
    type = json['type'];
    receiverRole = json['receiver_role'];
    senderRole = json['sender_role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['created_at'] = createdAt;
    data['description'] = description;
    data['id'] = id;
    data['receiver_id'] = receiverId;
    data['responseMessage'] = responseMessage;
    data['responseStatus'] = responseStatus;
    data['responseTimestamp'] = responseTimestamp;
    data['sender_id'] = senderId;
    data['status'] = status;
    data['title'] = title;
    data['type'] = type;
    data['receiver_role'] = receiverRole;
    data['sender_role'] = senderRole;
    return data;
  }
}
