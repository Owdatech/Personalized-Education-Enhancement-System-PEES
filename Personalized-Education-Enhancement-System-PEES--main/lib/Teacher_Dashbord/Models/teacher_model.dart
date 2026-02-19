enum TeacherListType { dashBoard, students, settings }

class TeacherModel {
  String? title;
  TeacherListType? type;
  String? fillImage;
  String? colorImage;
  int? index;

  TeacherModel(
      this.title, this.type, this.fillImage, this.colorImage, this.index);
}


