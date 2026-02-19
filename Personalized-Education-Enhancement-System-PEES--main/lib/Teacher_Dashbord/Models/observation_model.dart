class ObservationModel {
  List<Observations>? observations;

  ObservationModel({this.observations});

  ObservationModel.fromJson(Map<String, dynamic> json) {
    if (json['observations'] != null) {
      observations = <Observations>[];
      json['observations'].forEach((v) {
        observations!.add(Observations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (observations != null) {
      data['observations'] = observations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Observations {
  String? attachmentUrl;
  String? date;
  String? observation;
  String? subject;

  Observations({this.attachmentUrl, this.date, this.observation, this.subject});

  Observations.fromJson(Map<String, dynamic> json) {
    attachmentUrl = json['attachment_url'];
    date = json['date'];
    observation = json['observation'];
    subject = json['subject'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['attachment_url'] = attachmentUrl;
    data['date'] = date;
    data['observation'] = observation;
    data['subject'] = subject;
    return data;
  }
}