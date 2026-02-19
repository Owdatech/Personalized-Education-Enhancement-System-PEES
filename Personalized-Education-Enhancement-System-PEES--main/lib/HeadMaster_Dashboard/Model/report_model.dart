class ReportCardModel {
  final String grade;
  final Map<String, Subject> subjects;

  ReportCardModel({
    required this.grade,
    required this.subjects,
  });

  factory ReportCardModel.fromJson(Map<String, dynamic> json) {
    Map<String, Subject> parsedSubjects = {};
    if (json['subjects'] != null) {
      json['subjects'].forEach((key, value) {
        parsedSubjects[key] = Subject.fromJson(value);
      });
    }

    return ReportCardModel(
      grade: json['grade'] ?? "N/A",
      subjects: parsedSubjects,
    );
  }
}

class Subject {
  final List<History> history;

  Subject({required this.history});

  factory Subject.fromJson(Map<String, dynamic> json) {
    var historyList = (json['history'] as List?)?.map((e) => History.fromJson(e)).toList() ?? [];
    return Subject(history: historyList);
  }
}

class History {
  final String curriculumName;
  final String grade;
  final int marks;
  final String timestamp;
  final int? totalMark;

  History({
    required this.curriculumName,
    required this.grade,
    required this.marks,
    required this.timestamp,
    this.totalMark,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      curriculumName: json['curriculumName'] ?? "N/A",
      grade: json['grade'] ?? "N/A",
      marks: json['marks'] ?? 0,
      timestamp: json['timestamp'] ?? "N/A",
      totalMark: json['totalMark'],
    );
  }
}



// class ReportCardModel {
//   final String grade;
//   final List<Subject> subjects;
//   // final Attendance attendance;
//   // final ReportCard reportCard;

//   ReportCardModel({
//     required this.grade,

//     required this.subjects,
//     // required this.attendance,
//     // required this.reportCard,
//   });

//   factory ReportCardModel.fromJson(Map<String, dynamic> json) {
//     Map<String, dynamic>? subjectData = json['academicData']?['subjects'];

//     List<Subject> subjects = subjectData != null
//         ? subjectData.keys.map((key) {
//             var history = subjectData[key]?['history'] as List? ?? [];
//             var lastHistory = history.isNotEmpty ? history.last : {};

//             return Subject(
//               name: key,
//               curriculum: lastHistory['curriculumName'] ?? "",
//               marks: (lastHistory['marks'] as int?) ?? 0,
//               grade: lastHistory['grade'] ?? "",
//               timestamp: lastHistory['timestamp'] ?? "",
//               totalMark: (lastHistory['totalMark'] as int?) ?? 0,
//             );
//           }).toList()
//         : [];

//     return ReportCardModel(
//       grade: json['academicData']?['grade'] ?? "",
//       subjects: subjects,
//       // attendance: Attendance.fromJson(json['attendance'] ?? {}),
//       // reportCard: ReportCard.fromJson(json['reportCard'] ?? {}),
//     );
//   }
// }

// class Subject {
//   final String name;
//   final String curriculum;
//   final int marks;
//   final String grade;
//   final String timestamp;
//   final int totalMark;

//   Subject({
//     required this.name,
//     required this.curriculum,
//     required this.marks,
//     required this.grade,
//     required this.timestamp,
//     required this.totalMark,
//   });
// }

// class Attendance {
//   final int absentDays;
//   final int halfDays;
//   final int presentDays;
//   final int totalWorkingDays;

//   Attendance({
//     required this.absentDays,
//     required this.halfDays,
//     required this.presentDays,
//     required this.totalWorkingDays,
//   });

//   factory Attendance.fromJson(Map<String, dynamic> json) {
//     return Attendance(
//       absentDays: (json['absentDays'] as int?) ?? 0,
//       halfDays: (json['halfDays'] as int?) ?? 0,
//       presentDays: (json['presentDays'] as int?) ?? 0,
//       totalWorkingDays: (json['totalWorkingDays'] as int?) ?? 0,
//     );
//   }
// }

// class ReportCard {
//   final String activity;
//   final String grade;
//   final int obtainedMarks;
//   final int totalMarks;

//   ReportCard({
//     required this.activity,
//     required this.grade,
//     required this.obtainedMarks,
//     required this.totalMarks,
//   });

//   factory ReportCard.fromJson(Map<String, dynamic> json) {
//     return ReportCard(
//       activity: json['activity'] ?? "",
//       grade: json['grade'] ?? "",
//       obtainedMarks: (json['totalObtainedMarks'] as int?) ?? 0,
//       totalMarks: (json['totalMarks'] as int?) ?? 0,
//     );
//   }
// }
