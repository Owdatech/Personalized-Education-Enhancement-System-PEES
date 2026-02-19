class StudentProfileModel {
  String? address;
  String? classSection;
  String? email;
  String? grade;
  String? phoneNumber;
  String? photoUrl;
  String? studentId;
  String? studentName;

  StudentProfileModel(
      {this.address,
      this.classSection,
      this.email,
      this.grade,
      this.phoneNumber,
      this.photoUrl,
      this.studentId,
      this.studentName});

  StudentProfileModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    classSection = json['classSection'];
    email = json['email'];
    grade = json['grade'];
    phoneNumber = json['phoneNumber'];
    photoUrl = json['photoUrl'];
    studentId = json['studentId'];
    studentName = json['studentName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['address'] = address;
    data['classSection'] = classSection;
    data['email'] = email;
    data['grade'] = grade;
    data['phoneNumber'] = phoneNumber;
    data['photoUrl'] = photoUrl;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    return data;
  }
}
