class Curriculum {
  final String curriculumId;
  final String curriculumName;
  final String grade;
  final String subject;

  Curriculum({
    required this.curriculumId,
    required this.curriculumName,
    required this.grade,
    required this.subject,
  });

  // Factory method to create an object from JSON
  factory Curriculum.fromJson(Map<String, dynamic> json) {
    return Curriculum(
      curriculumId: json['curriculum_id'],
      curriculumName: json['curriculum_name'].trim(), // Trim to remove extra spaces
      grade: json['grade'],
      subject: json['subject'],
    );
  }
}