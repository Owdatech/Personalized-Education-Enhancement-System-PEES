class FeedbackModel {
  List<Feedback>? feedback;
  String? status;

  FeedbackModel({this.feedback, this.status});

  FeedbackModel.fromJson(Map<String, dynamic> json) {
    if (json['feedback'] != null) {
      feedback = <Feedback>[];
      json['feedback'].forEach((v) {
        feedback!.add(new Feedback.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.feedback != null) {
      data['feedback'] = this.feedback!.map((v) => v.toJson()).toList();
    }
    data['status'] = this.status;
    return data;
  }
}

class Feedback {
  String? feedback;
  String? studentid;
  String? timestamp;

  Feedback({this.feedback, this.studentid, this.timestamp});

  Feedback.fromJson(Map<String, dynamic> json) {
    feedback = json['feedback'];
    studentid = json['studentid'];
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['feedback'] = this.feedback;
    data['studentid'] = this.studentid;
    data['timestamp'] = this.timestamp;
    return data;
  }
}