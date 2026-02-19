class ProgressModel {
  String? pdfUrl;
  // String? studentId;
  String? status;

  ProgressModel({this.pdfUrl, 
  // this.studentId, 
  this.status});

  ProgressModel.fromJson(Map<String, dynamic> json) {
    pdfUrl = json['pdf_url'];
    // studentId = json['student_id'];
    status = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pdf_url'] = pdfUrl;
    // data['student_id'] = studentId;
    data['message'] = status;
    return data;
  }
}
