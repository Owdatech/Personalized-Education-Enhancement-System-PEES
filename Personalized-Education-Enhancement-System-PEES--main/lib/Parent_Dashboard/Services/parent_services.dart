import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:pees/Parent_Dashboard/Models/alerts_noti_model.dart';
import 'package:pees/Parent_Dashboard/Models/parent_model.dart';
import 'package:pees/Parent_Dashboard/Models/recentUpdateModel.dart';
import 'package:pees/Parent_Dashboard/Models/resourceModel.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ParentFor { all, sara }

class ParentService extends BaseVM {
  ParentFor selectedType = ParentFor.all;
  int selectedIndex = 0;
  List<Students> studentsList = [];
  List<RecentUpdates> recentUpdatesList = [];
  List<Resources> resourcesList = [];
  // List<AlertsModel>  alertslist =[];
  List<Alerts> alertsList = [];
  List<Notifications> notificationsList = [];
  List<LowMarkAlertItem> lowMarkAlerts = [];
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  Future<List<Students>> fetchChildernDetails(String userId) async {
    try {
      setLoading(true);
      String url = "${Config.baseURL}get_students?userId=$userId";
      print("Children Info URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> studentsJson = data['students'];
        studentsList = studentsJson.map((e) => Students.fromJson(e)).toList();
        print("Respone : $data");
        setLoading(false);
        return studentsList;
      } else {
        setLoading(false);
        print("Repsonse Code : ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Request failed: $e");
      setLoading(false);
      return [];
    }
  }

  Future<ProgressModel?> fetchProgressReport(
      String parentId, String studentId) async {
    setLoading(true);
    try {
      final url = Uri.parse(
          '${Config.baseURL}api/progress-report?parent_id=$parentId&student_id=$studentId');
      print("Fetch Report card info : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        ProgressModel model =
            ProgressModel.fromJson(json.decode(response.body));
        print(
            "Progress Report Repsonse Code : ${response.statusCode} ${response.body}");
        setLoading(false);
        return model;
      } else {
        print(
            "Progress Report Repsonse Code : ${response.statusCode} ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (e) {
      setLoading(false);
      print("Progress Report failed : $e");
      return null;
    }
  }

  Future<int?> fetchRecentUpdates(String parentId) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/recent-updates?parent_id=$parentId&lang=$selectedLanguage";
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        RecentUpdateModel model = RecentUpdateModel.fromJson(data);
        recentUpdatesList = model.recentUpdates ?? [];
        print("Respone : $data");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  List<dynamic> students = [];
  Map<String, dynamic> recommendations = {};

  Future<int?> fetchResources(String parentId, String lang) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/resources-analysis?parent_id=$parentId&lang=$lang";
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        students = data["students"] as List<dynamic>;
        recommendations = data["recommendations"] as Map<String, dynamic>;

        print("Respone : $data");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  Future<int?> fetchAlertsNotification(String parentId) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/alerts-notifications?teacher_id=$parentId&lang=$selectedLanguage";
      print("Alerts & Notification URL : $apiUrl");
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        alertsList = (jsonData['alerts'] as List)
            .map((item) => Alerts.fromJson(item))
            .toList();
        notificationsList = (jsonData['notifications'] as List)
            .map((item) => Notifications.fromJson(item))
            .toList();
        print("Respone : $jsonData");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  String? _readStudentField(Map<dynamic, dynamic> student, List<String> keys) {
    for (final key in keys) {
      final value = student[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != "null") {
        return value;
      }
    }
    return null;
  }

  String? _readNestedName(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') return trimmed;
      return null;
    }
    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      final candidate = map['name'] ??
          map['teacherName'] ??
          map['teacher_name'] ??
          map['fullName'] ??
          map['full_name'] ??
          map['displayName'] ??
          map['display_name'];
      return _readNestedName(candidate);
    }
    if (value is List) {
      for (final item in value) {
        final candidate = _readNestedName(item);
        if (candidate != null) return candidate;
      }
    }
    return null;
  }

  String _extractTeacherName(
    Map<dynamic, dynamic> student,
    Map<dynamic, dynamic> reportDecoded, {
    Map<dynamic, dynamic>? latestHistory,
  }) {
    final fromStudentDirect = _readStudentField(student, [
      'assignedTeacherName',
      'assigned_teacher_name',
      'teacherName',
      'teacher_name',
      'assignedTeacher',
      'assigned_teacher',
      'classTeacher',
      'class_teacher',
      'advisorName',
      'advisor_name',
    ]);
    if (fromStudentDirect != null) return fromStudentDirect;

    final nestedStudentCandidates = [
      student['assignedTeacher'],
      student['assigned_teacher'],
      student['teacher'],
      student['teacherInfo'],
      student['teacher_info'],
      student['classTeacher'],
      student['class_teacher'],
    ];
    for (final candidate in nestedStudentCandidates) {
      final name = _readNestedName(candidate);
      if (name != null) return name;
    }

    final reportCandidates = [
      reportDecoded['teacherName'],
      reportDecoded['teacher_name'],
      reportDecoded['assignedTeacherName'],
      reportDecoded['assigned_teacher_name'],
      reportDecoded['teacher'],
      reportDecoded['teacherInfo'],
      reportDecoded['teacher_info'],
      reportDecoded['academicData'],
    ];
    for (final candidate in reportCandidates) {
      final name = _readNestedName(candidate);
      if (name != null) return name;
    }

    if (latestHistory != null) {
      final historyCandidates = [
        latestHistory['teacherName'],
        latestHistory['teacher_name'],
        latestHistory['teacher'],
        latestHistory['updatedBy'],
        latestHistory['updated_by'],
        latestHistory['createdBy'],
        latestHistory['created_by'],
      ];
      for (final candidate in historyCandidates) {
        final name = _readNestedName(candidate);
        if (name != null) return name;
      }
    }

    return 'N/A';
  }

  String? _extractTeacherIdFromAny(Map<dynamic, dynamic> map) {
    final id = _readStudentField(map, [
      'assignedTeacherId',
      'assigned_teacher_id',
      'teacherId',
      'teacher_id',
      'assignedTo',
      'assigned_to',
      'advisorId',
      'advisor_id',
    ]);
    return id;
  }

  String _normalizeText(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _normalizeId(String input) => input.trim().toLowerCase();

  String _normalizeGradeText(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  bool _looksLikeGrade(String text) {
    final upper = text.toUpperCase().trim();
    return upper.contains('GRADE') || RegExp(r'\b\d{1,2}\b').hasMatch(upper);
  }

  String _gradeSubjectKey(String grade, String subject) =>
      '${_normalizeGradeText(grade)}|${_normalizeText(subject)}';

  void _registerTeacherAssignment(
    Map<String, String> gradeSubjectTeacherMap,
    String teacherName,
    String? grade,
    String? subject,
  ) {
    final g = grade?.trim() ?? '';
    final s = subject?.trim() ?? '';
    if (g.isEmpty || s.isEmpty) return;
    final key = _gradeSubjectKey(g, s);
    gradeSubjectTeacherMap.putIfAbsent(key, () => teacherName);
  }

  void _collectTeacherAssignments(
    dynamic payload,
    String teacherName,
    Map<String, String> gradeSubjectTeacherMap, {
    String? inheritedGrade,
  }) {
    if (payload == null) return;

    if (payload is List) {
      for (final item in payload) {
        _collectTeacherAssignments(
          item,
          teacherName,
          gradeSubjectTeacherMap,
          inheritedGrade: inheritedGrade,
        );
      }
      return;
    }

    if (payload is! Map) {
      if (payload is String && inheritedGrade != null) {
        _registerTeacherAssignment(
            gradeSubjectTeacherMap, teacherName, inheritedGrade, payload);
      }
      return;
    }

    final map = payload.cast<dynamic, dynamic>();
    final gradeFromFields = _readStudentField(map, [
      'grade',
      'gradeName',
      'grade_name',
      'classGrade',
      'class_grade',
    ]);
    final subjectFromFields = _readStudentField(map, [
      'subject',
      'subjectName',
      'subject_name',
    ]);
    final activeGrade = gradeFromFields ?? inheritedGrade;

    _registerTeacherAssignment(
      gradeSubjectTeacherMap,
      teacherName,
      activeGrade,
      subjectFromFields,
    );

    final subjectsValue = map['subjects'] ?? map['subjects_list'];
    if (subjectsValue is List) {
      for (final subject in subjectsValue) {
        _registerTeacherAssignment(
          gradeSubjectTeacherMap,
          teacherName,
          activeGrade,
          subject?.toString(),
        );
      }
    } else if (subjectsValue is String) {
      _registerTeacherAssignment(
        gradeSubjectTeacherMap,
        teacherName,
        activeGrade,
        subjectsValue,
      );
    }

    if (map['grades'] != null) {
      _collectTeacherAssignments(
        map['grades'],
        teacherName,
        gradeSubjectTeacherMap,
        inheritedGrade: activeGrade,
      );
    }

    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is! Map && value is! List) continue;

      final nextGrade = _looksLikeGrade(key) ? key : activeGrade;
      _collectTeacherAssignments(
        value,
        teacherName,
        gradeSubjectTeacherMap,
        inheritedGrade: nextGrade,
      );
    }
  }

  void _collectTeacherAssignmentsFromAssignedGrades(
    dynamic assignedGrades,
    String teacherName,
    Map<String, String> gradeSubjectTeacherMap,
  ) {
    if (assignedGrades is! Map) return;
    final gradesMap = assignedGrades.cast<dynamic, dynamic>();

    for (final gradeEntry in gradesMap.entries) {
      final gradeName = gradeEntry.key.toString().trim();
      final classes = gradeEntry.value;
      if (gradeName.isEmpty || classes is! Map) continue;

      final classMap = classes.cast<dynamic, dynamic>();
      for (final classEntry in classMap.entries) {
        final subjects = classEntry.value;
        if (subjects is! List) continue;
        for (final subject in subjects) {
          final subjectName = subject?.toString().trim();
          if (subjectName == null || subjectName.isEmpty) continue;
          _registerTeacherAssignment(
            gradeSubjectTeacherMap,
            teacherName,
            gradeName,
            subjectName,
          );
        }
      }
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  double _normalizeToTen(double marks, double? totalMark) {
    if (totalMark != null && totalMark > 0) {
      return (marks / totalMark) * 10.0;
    }
    return marks;
  }

  int _extractGradeOrder(String gradeText) {
    final normalized = gradeText.toUpperCase().replaceAll('_', ' ');
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (match == null) return 999;
    return int.tryParse(match.group(1)!) ?? 999;
  }

  DateTime _safeParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<int?> fetchLowMarksAlertsForHeadmaster() async {
    try {
      setLoading(true);
      lowMarkAlerts = [];

      final studentsResponse = await http.get(
        Uri.parse("${Config.baseURL}students/list"),
        headers: {"Content-Type": "application/json"},
      );

      if (studentsResponse.statusCode != 200) {
        setLoading(false);
        return studentsResponse.statusCode;
      }

      final studentsDecoded = json.decode(studentsResponse.body);
      final List<dynamic> studentsList = studentsDecoded is List
          ? studentsDecoded
          : (studentsDecoded is Map && studentsDecoded['students'] is List
              ? List<dynamic>.from(studentsDecoded['students'])
              : <dynamic>[]);

      final Map<String, String> teacherIdToName = {};
      final Map<String, String> gradeSubjectTeacherMap = {};
      try {
        final prefs = await SharedPreferences.getInstance();
        final jwtToken = prefs.getString('jwtToken') ?? '';
        final token = prefs.getString('token') ?? '';
        final userHeaders = <String, String>{
          "Content-Type": "application/json",
        };
        if (jwtToken.trim().isNotEmpty) {
          userHeaders['Authorization'] = 'Bearer $jwtToken';
        } else if (token.trim().isNotEmpty) {
          userHeaders['Authorization'] = 'Bearer $token';
        }

        final usersResponse = await http.get(
          Uri.parse("${Config.baseURL}api/headmaster/users"),
          headers: userHeaders,
        );
        if (usersResponse.statusCode == 200) {
          final usersDecoded = json.decode(usersResponse.body);
          final List<dynamic> users = usersDecoded is List
              ? usersDecoded
              : (usersDecoded is Map && usersDecoded['users'] is List
                  ? List<dynamic>.from(usersDecoded['users'])
                  : <dynamic>[]);
          for (final userRaw in users) {
            if (userRaw is! Map) continue;
            final user = userRaw.cast<dynamic, dynamic>();
            final role = (user['role'] ?? '').toString().toLowerCase().trim();
            if (role != 'teacher') continue;
            final teacherId =
                _readStudentField(user, ['userId', 'user_id', 'id']);
            final teacherName =
                _readStudentField(user, ['name', 'fullName', 'full_name']);
            if (teacherId != null && teacherName != null) {
              teacherIdToName[_normalizeId(teacherId)] = teacherName;
              _collectTeacherAssignmentsFromAssignedGrades(
                user['assignedGrades'],
                teacherName,
                gradeSubjectTeacherMap,
              );
              _collectTeacherAssignments(
                user['assignedGrades'] ?? user['grades'],
                teacherName,
                gradeSubjectTeacherMap,
              );
            }
          }
        }
      } catch (_) {
        // Keep low-marks flow working even if teacher lookup endpoint fails.
      }

      final List<LowMarkAlertItem> collected = [];

      Future<void> processStudent(dynamic studentRaw) async {
        if (studentRaw is! Map) return;
        final student = studentRaw.cast<dynamic, dynamic>();

        final studentId =
            _readStudentField(student, ['studentId', 'student_id', 'id']);
        if (studentId == null) return;

        final studentName =
            _readStudentField(student, ['name', 'student_name']) ?? "N/A";
        final studentEmail = _readStudentField(student, ['email']) ?? "-";
        final fallbackGrade =
            _readStudentField(student, ['grade', 'gradeName']) ?? "Unknown";
        String teacherName = 'N/A';
        final teacherIdFromStudent = _extractTeacherIdFromAny(student);
        if (teacherIdFromStudent != null &&
            teacherIdToName.containsKey(_normalizeId(teacherIdFromStudent))) {
          teacherName = teacherIdToName[_normalizeId(teacherIdFromStudent)]!;
        }

        final reportResponse = await http.get(
          Uri.parse('${Config.baseURL}api/student/report-card/$studentId'),
          headers: {"Content-Type": "application/json"},
        );

        if (reportResponse.statusCode != 200) return;
        final reportDecoded = json.decode(reportResponse.body);
        if (reportDecoded is! Map) return;
        if (teacherName == 'N/A') {
          teacherName = _extractTeacherName(
              student, reportDecoded.cast<dynamic, dynamic>());
        }

        final academicData = reportDecoded['academicData'];
        if (academicData is! Map) return;

        final reportGrade = academicData['grade']?.toString().trim();
        final grade = (reportGrade != null && reportGrade.isNotEmpty)
            ? reportGrade
            : fallbackGrade;

        final subjectsRaw = academicData['subjects'];
        if (subjectsRaw is! Map) return;

        for (final entry in subjectsRaw.entries) {
          final subjectName = entry.key.toString().trim();
          if (subjectName.isEmpty) continue;
          final details = entry.value;
          if (details is! Map) continue;

          final history = details['history'];
          if (history is! List || history.isEmpty) continue;

          final latest = history.last;
          if (latest is! Map) continue;
          final latestMap = latest.cast<dynamic, dynamic>();
          String itemTeacherName = teacherName;
          final mappedTeacher =
              gradeSubjectTeacherMap[_gradeSubjectKey(grade, subjectName)];
          if (mappedTeacher != null && mappedTeacher.trim().isNotEmpty) {
            itemTeacherName = mappedTeacher;
          }
          if (itemTeacherName == 'N/A') {
            final teacherIdFromHistory = _extractTeacherIdFromAny(latestMap);
            if (teacherIdFromHistory != null &&
                teacherIdToName
                    .containsKey(_normalizeId(teacherIdFromHistory))) {
              itemTeacherName =
                  teacherIdToName[_normalizeId(teacherIdFromHistory)]!;
            }
          }
          if (itemTeacherName == 'N/A') {
            itemTeacherName = _extractTeacherName(
              student,
              reportDecoded.cast<dynamic, dynamic>(),
              latestHistory: latestMap,
            );
          }

          final marks = _asDouble(latestMap['marks']);
          if (marks == null) continue;
          final totalMark = _asDouble(latestMap['totalMark']);
          final normalized = _normalizeToTen(marks, totalMark);

          if (normalized < 6.0) {
            final timestamp = latestMap['timestamp']?.toString();
            collected.add(
              LowMarkAlertItem(
                studentId: studentId,
                studentName: studentName,
                studentEmail: studentEmail,
                grade: grade,
                subject: subjectName,
                teacherName: itemTeacherName,
                normalizedMarkOutOfTen: normalized,
                rawMarks: marks,
                totalMarks: totalMark,
                timestamp: timestamp,
              ),
            );
          }
        }
      }

      await Future.wait(studentsList.map(processStudent));

      collected.sort((a, b) {
        final aDate = _safeParseDate(a.timestamp);
        final bDate = _safeParseDate(b.timestamp);
        final byDateDesc = bDate.compareTo(aDate);
        if (byDateDesc != 0) return byDateDesc;

        final aOrder = _extractGradeOrder(a.grade);
        final bOrder = _extractGradeOrder(b.grade);
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);

        final byStudent = a.studentName.compareTo(b.studentName);
        if (byStudent != 0) return byStudent;
        return a.subject.compareTo(b.subject);
      });

      lowMarkAlerts = collected;
      setLoading(false);
      return 200;
    } catch (error) {
      setLoading(false);
      print('Error fetching low marks alerts: $error');
      return null;
    }
  }

  List<ParentModel> dashBoardList = [
    ParentModel("DASHBOARD", ParentListType.dashBoard, AppImage.dashboardFill,
        AppImage.dashboardWhite),
    ParentModel("SETTINGS", ParentListType.settings, AppImage.settingsFill,
        AppImage.settingsWhite)
  ];
}

class Students {
  String? name;
  String? photoUrl;
  String? studentId;
  String? assignTeacherName;
  String? className;
  String? email;
  String? grade;

  Students(
      {this.name,
      this.photoUrl,
      this.studentId,
      this.assignTeacherName,
      this.className,
      this.email,
      this.grade});

  factory Students.fromJson(Map<String, dynamic> json) {
    return Students(
      name: json['name'],
      photoUrl: json['photoUrl'],
      studentId: json['studentId'],
      assignTeacherName: json['assignedTeacherName'],
      className: json['class'],
      email: json['email'],
      grade: json['grade'],
    );
  }
}

enum ParentListType { dashBoard, settings }

class ParentModel {
  String title;
  ParentListType type;
  String fillImage;
  String colorImage;

  ParentModel(this.title, this.type, this.fillImage, this.colorImage);
}

class LowMarkAlertItem {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String grade;
  final String subject;
  final String teacherName;
  final double normalizedMarkOutOfTen;
  final double rawMarks;
  final double? totalMarks;
  final String? timestamp;

  LowMarkAlertItem({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.grade,
    required this.subject,
    required this.teacherName,
    required this.normalizedMarkOutOfTen,
    required this.rawMarks,
    required this.totalMarks,
    required this.timestamp,
  });
}
