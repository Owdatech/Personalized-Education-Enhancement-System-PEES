// ignore: file_names
class ResourceModel {
  String? parentId;
  List<Resources>? resources;

  ResourceModel({this.parentId, this.resources});

  ResourceModel.fromJson(Map<String, dynamic> json) {
    parentId = json['parent_id'];
    if (json['resources'] != null) {
      resources = <Resources>[];
      json['resources'].forEach((v) {
        resources!.add(Resources.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['parent_id'] = parentId;
    if (resources != null) {
      data['resources'] = resources!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Resources {
  String? description;
  String? planId;
  String? resource;
  String? studentId;

  Resources({this.description, this.planId, this.resource, this.studentId});

  Resources.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    planId = json['plan_id'];
    resource = json['resource'];
    studentId = json['student_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['plan_id'] = planId;
    data['resource'] = resource;
    data['student_id'] = studentId;
    return data;
  }
}