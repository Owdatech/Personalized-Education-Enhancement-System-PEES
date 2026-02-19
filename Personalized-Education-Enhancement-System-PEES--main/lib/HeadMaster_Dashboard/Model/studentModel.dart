class StudentModel {
  String? address;
  String? classSection;
  String? email;
  String? grade;
  String? phonenumber;
  String? photourl;
  String? status;
  String? studentId;
  String? studentName;
  String? planId;
  int? version;
  String? classId;
  String? gradeId;


  StudentModel(
      {this.address,
      this.classSection,
      this.email,
      this.grade,
      this.phonenumber,
      this.photourl,
      this.status,
      this.studentId,
      this.studentName,
      this.planId,
      this.version,
      this.classId,
      this.gradeId
      });

  StudentModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    classSection = json['classSection'];
    email = json['email'];
    grade = json['grade'];
    phonenumber = json['phonenumber'];
    photourl = json['photourl'];
    status = json['status'];
    studentId = json['student_id'];
    studentName = json['student_name'];
    planId = json['planId'];
    version = json['version'];
    classId = json['class_ref'];
    gradeId = json['grade_ref'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address'] = address;
    data['classSection'] = classSection;
    data['email'] = email;
    data['grade'] = grade;
    data['phonenumber'] = phonenumber;
    data['photourl'] = photourl;
    data['status'] = status;
    data['student_id'] = studentId;
    data['student_name'] = studentName;
    data['planId'] = planId;
    data['version'] = version;
    data['class_ref'] = classId;
    data['grade_ref'] = gradeId;
    return data;
  }
}
