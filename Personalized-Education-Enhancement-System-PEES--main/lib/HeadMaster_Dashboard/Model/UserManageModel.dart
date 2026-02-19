class UserManageModel {
  String? email;
  String? name;
  String? role;
  String? status;
  String? userID;
  Map<String, dynamic>? assignedGrades;

  UserManageModel({
    this.email,
    this.name,
    this.role,
    this.status,
    this.userID,
    this.assignedGrades,
  });

  UserManageModel.fromJson(Map<String, dynamic> json) {
    email = json["email"];
    name = json['name'];
    role = json['role'];
    status = json['status'];
    userID = json['userId'];
    // ignore: unused_label
    if (json['assignedGrades'] != null && json['assignedGrades'] is Map) {
      Map<String, dynamic> grades =
          Map<String, dynamic>.from(json['assignedGrades']);

      // If "grades" key exists, extract its contents
      if (grades.containsKey('grades') && grades['grades'] is Map) {
        assignedGrades = Map<String, dynamic>.from(grades['grades']);
      } else {
        assignedGrades = grades;
      }
    } else {
      assignedGrades = {};
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['email'] = email;
    data['name'] = name;
    data['role'] = role;
    data['status'] = status;
    data['userId'] = userID;
    data['assignedGrades'] = assignedGrades;
    return data;
  }
}
