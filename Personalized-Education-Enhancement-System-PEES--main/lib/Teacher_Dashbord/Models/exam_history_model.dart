class ExamHistory {
  final String curriculumName;
  final String date;
  final String evaluatedText;
  final String examName;
  final String subjectName;
  final String evaluatedId;

  ExamHistory({
    required this.curriculumName,
    required this.date,
    required this.evaluatedText,
    required this.examName,
    required this.subjectName,
    required this.evaluatedId,
  });

  factory ExamHistory.fromJson(Map<String, dynamic> json) {
    return ExamHistory(
      curriculumName: json['curriculum_name'],
      date: json['date'],
      evaluatedText: json['evaluated_text'],
      examName: json['exam_name'],
      subjectName: json['subject_name'],
      evaluatedId: json['evaluation_id'],
    );
  }
}
