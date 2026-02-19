class RecentUpdateModel {
  List<RecentUpdates>? recentUpdates;

  RecentUpdateModel({this.recentUpdates});

  RecentUpdateModel.fromJson(Map<String, dynamic> json) {
    if (json['recent_updates'] != null) {
      recentUpdates = <RecentUpdates>[];
      json['recent_updates'].forEach((v) {
        recentUpdates!.add(new RecentUpdates.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (recentUpdates != null) {
      data['recent_updates'] =
          recentUpdates!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RecentUpdates {
  String? attachmentUrl;
  String? date;
  String? observation;
  String? studentId;
  String? subject;
  String? type;

  RecentUpdates(
      {this.attachmentUrl,
      this.date,
      this.observation,
      this.studentId,
      this.subject,
      this.type});

  RecentUpdates.fromJson(Map<String, dynamic> json) {
    attachmentUrl = json['attachment_url'];
    date = json['date'];
    observation = json['observation'];
    studentId = json['student_id'];
    subject = json['subject'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['attachment_url'] = attachmentUrl;
    data['date'] = date;
    data['observation'] = observation;
    data['student_id'] = studentId;
    data['subject'] = subject;
    data['type'] = type;
    return data;
  }
}