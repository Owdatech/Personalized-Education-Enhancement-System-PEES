import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ReposrtsScreen extends StatefulWidget {
  const ReposrtsScreen({super.key});

  @override
  State<ReposrtsScreen> createState() => _ReposrtsScreenState();
}

class _ReposrtsScreenState extends State<ReposrtsScreen> {
  static const String _teachersCacheKey = 'cached_headmaster_teachers_v1';
  List<_TeacherOption> _teacherOptions = [];
  String? _selectedTeacherId;
  bool _loadingTeachers = false;
  bool _loadingTeacherReport = false;
  List<_ClassReportItem> _classReports = [];
  String? _teacherReportError;

  @override
  void initState() {
    _fetchTeachers();
    super.initState();
  }

  String _normalizeText(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _normalizeGrade(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  String _normalizeClass(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('class', '')
        .replaceAll('section', '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  String _classKey(String grade, String className) =>
      '${_normalizeGrade(grade)}|${_normalizeText(className)}';

  double _toOutOfTen(double marks, double? totalMark) {
    if (totalMark != null && totalMark > 0) {
      return (marks / totalMark) * 10.0;
    }
    return marks;
  }

  Map<String, String> _buildAuthHeaders(String? jwtToken, String? token) {
    final headers = <String, String>{"Content-Type": "application/json"};
    if ((jwtToken ?? '').trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${jwtToken!.trim()}';
    } else if ((token ?? '').trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token!.trim()}';
    }
    return headers;
  }

  Future<void> _fetchTeachers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _loadingTeachers = true;
      });

      // Fast path: render cached teachers immediately, then refresh in background.
      final cachedRaw = prefs.getString(_teachersCacheKey);
      if (cachedRaw != null && cachedRaw.trim().isNotEmpty) {
        try {
          final cachedDecoded = json.decode(cachedRaw);
          if (cachedDecoded is List) {
            final cachedTeachers = cachedDecoded
                .whereType<Map>()
                .map((e) => e.cast<dynamic, dynamic>())
                .map((u) => _TeacherOption(
                      id: (u['id'] ?? '').toString(),
                      name: (u['name'] ?? '').toString(),
                      assignedGrades: (u['assignedGrades'] is Map)
                          ? Map<dynamic, dynamic>.from(
                              u['assignedGrades'] as Map)
                          : <dynamic, dynamic>{},
                    ))
                .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (cachedTeachers.isNotEmpty) {
              setState(() {
                _teacherOptions = cachedTeachers;
                _selectedTeacherId ??= cachedTeachers.first.id;
                _teacherReportError = null;
              });

              if (_classReports.isEmpty && _selectedTeacherId != null) {
                _buildTeacherClassReport(_selectedTeacherId!);
              }
            }
          }
        } catch (_) {
          // Ignore malformed cache.
        }
      }

      final jwtToken = prefs.getString('jwtToken');
      final token = prefs.getString('token');
      final headers = _buildAuthHeaders(jwtToken, token);

      final response = await http.get(
        Uri.parse("${Config.baseURL}api/headmaster/users"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        setState(() {
          _teacherReportError =
              "${"failedToLoadTeachers".tr} (${response.statusCode}).";
        });
        return;
      }

      final decoded = json.decode(response.body);
      final users = decoded is List
          ? decoded
          : (decoded is Map && decoded['users'] is List)
              ? List<dynamic>.from(decoded['users'])
              : <dynamic>[];

      final teachers = users
          .whereType<Map>()
          .map((e) => e.cast<dynamic, dynamic>())
          .where((u) => (u['role'] ?? '').toString().toLowerCase() == 'teacher')
          .map((u) => _TeacherOption(
                id: (u['userId'] ?? u['user_id'] ?? u['id'] ?? '')
                    .toString()
                    .trim(),
                name: (u['name'] ?? '').toString().trim(),
                assignedGrades: (u['assignedGrades'] is Map)
                    ? Map<dynamic, dynamic>.from(u['assignedGrades'] as Map)
                    : <dynamic, dynamic>{},
              ))
          .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _teacherOptions = teachers;
        if (_selectedTeacherId == null && teachers.isNotEmpty) {
          _selectedTeacherId = teachers.first.id;
        }
        _teacherReportError = null;
        _loadingTeachers = false;
      });

      final cachePayload = teachers
          .map((t) => {
                'id': t.id,
                'name': t.name,
                'assignedGrades': t.assignedGrades,
              })
          .toList();
      await prefs.setString(_teachersCacheKey, json.encode(cachePayload));

      if (_selectedTeacherId != null && _classReports.isEmpty) {
        _buildTeacherClassReport(_selectedTeacherId!);
      }
    } catch (e) {
      setState(() {
        _loadingTeachers = false;
        _teacherReportError = "unableToLoadTeachers".tr;
      });
      debugPrint("Fetch teachers failed: $e");
    }
  }

  List<_ClassAssignment> _parseTeacherAssignments(_TeacherOption teacher) {
    final assignments = <_ClassAssignment>[];
    final raw = teacher.assignedGrades;
    final gradesNode = raw['grades'] is Map ? raw['grades'] : raw;
    if (gradesNode is! Map) return assignments;

    final gradeMap = gradesNode.cast<dynamic, dynamic>();
    for (final gradeEntry in gradeMap.entries) {
      final gradeName = gradeEntry.key.toString().trim();
      final classesNode = gradeEntry.value;
      if (gradeName.isEmpty || classesNode is! Map) continue;
      final classesMap = classesNode.cast<dynamic, dynamic>();

      for (final classEntry in classesMap.entries) {
        final className = classEntry.key.toString().trim();
        final subjectsNode = classEntry.value;
        if (className.isEmpty || subjectsNode is! List) continue;
        final subjects = subjectsNode
            .map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        if (subjects.isEmpty) continue;
        assignments.add(_ClassAssignment(
          grade: gradeName,
          className: className,
          subjects: subjects,
        ));
      }
    }

    final dedup = <String, _ClassAssignment>{};
    for (final a in assignments) {
      dedup[_classKey(a.grade, a.className)] = a;
    }
    return dedup.values.toList()
      ..sort((a, b) {
        final byGrade = a.grade.compareTo(b.grade);
        if (byGrade != 0) return byGrade;
        return a.className.compareTo(b.className);
      });
  }

  Future<void> _buildTeacherClassReport(String teacherId) async {
    final selectedTeacher = _teacherOptions
        .where((t) => t.id == teacherId)
        .cast<_TeacherOption?>()
        .firstWhere((t) => t != null, orElse: () => null);
    if (selectedTeacher == null) {
      setState(() {
        _classReports = [];
        _teacherReportError = "teacherNotFound".tr;
      });
      return;
    }

    setState(() {
      _loadingTeacherReport = true;
      _teacherReportError = null;
      _classReports = [];
    });

    try {
      final studentsResp = await http.get(
        Uri.parse("${Config.baseURL}students/list"),
        headers: {"Content-Type": "application/json"},
      );
      if (studentsResp.statusCode != 200) {
        setState(() {
          _teacherReportError =
              "${"failedToLoadStudents".tr} (${studentsResp.statusCode}).";
          _loadingTeacherReport = false;
        });
        return;
      }

      final studentsDecoded = json.decode(studentsResp.body);
      final students = studentsDecoded is List
          ? studentsDecoded
          : (studentsDecoded is Map && studentsDecoded['students'] is List)
              ? List<dynamic>.from(studentsDecoded['students'])
              : <dynamic>[];

      final assignments = _parseTeacherAssignments(selectedTeacher);
      if (assignments.isEmpty) {
        setState(() {
          _classReports = [];
          _loadingTeacherReport = false;
        });
        return;
      }

      final reports = <_ClassReportItem>[];
      for (final assignment in assignments) {
        final matchedStudents = students
            .whereType<Map>()
            .map((s) => s.cast<dynamic, dynamic>())
            .where((s) {
          final sGrade = (s['grade'] ?? s['gradeName'] ?? '').toString().trim();
          final sClass = (s['classSection'] ??
                  s['class'] ??
                  s['class_name'] ??
                  s['section'] ??
                  '')
              .toString()
              .trim();
          final sameGrade =
              _normalizeGrade(sGrade) == _normalizeGrade(assignment.grade);
          final sameClass =
              _normalizeClass(sClass) == _normalizeClass(assignment.className);
          return sameGrade && sameClass;
        }).toList();

        if (matchedStudents.isEmpty) {
          reports.add(_ClassReportItem(
            grade: assignment.grade,
            className: assignment.className,
            averageOutOfTen: null,
            lowStudents: [],
          ));
          continue;
        }

        final classMarks = <double>[];
        final lows = <_LowStudentMark>[];

        for (final student in matchedStudents) {
          final studentId = (student['studentId'] ??
                  student['student_id'] ??
                  student['id'] ??
                  '')
              .toString()
              .trim();
          if (studentId.isEmpty) continue;

          final studentName =
              (student['name'] ?? student['student_name'] ?? 'N/A').toString();

          final reportResp = await http.get(
            Uri.parse('${Config.baseURL}api/student/report-card/$studentId'),
            headers: {"Content-Type": "application/json"},
          );
          if (reportResp.statusCode != 200) continue;

          final reportDecoded = json.decode(reportResp.body);
          if (reportDecoded is! Map) continue;
          final academicData = reportDecoded['academicData'];
          if (academicData is! Map) continue;
          final subjectsNode = academicData['subjects'];
          if (subjectsNode is! Map) continue;

          final subjectsMap = subjectsNode.cast<dynamic, dynamic>();
          for (final taughtSubject in assignment.subjects) {
            final subjectEntry = subjectsMap.entries
                .cast<MapEntry<dynamic, dynamic>?>()
                .firstWhere(
                  (e) =>
                      e != null &&
                      _normalizeText(e.key.toString()) ==
                          _normalizeText(taughtSubject),
                  orElse: () => null,
                );
            if (subjectEntry == null) continue;

            final details = subjectEntry.value;
            if (details is! Map) continue;
            final history = details['history'];
            if (history is! List || history.isEmpty) continue;
            final latest = history.last;
            if (latest is! Map) continue;

            final marksRaw = latest['marks'];
            final totalRaw = latest['totalMark'];
            final marks = marksRaw is num
                ? marksRaw.toDouble()
                : double.tryParse(marksRaw.toString());
            final total = totalRaw is num
                ? totalRaw.toDouble()
                : double.tryParse(totalRaw.toString());
            if (marks == null) continue;

            final outOfTen = _toOutOfTen(marks, total);
            classMarks.add(outOfTen);
            if (outOfTen < 6.0) {
              lows.add(_LowStudentMark(
                studentId: studentId,
                studentName: studentName,
                subject: taughtSubject,
                markOutOfTen: outOfTen,
              ));
            }
          }
        }

        final average = classMarks.isEmpty
            ? null
            : classMarks.reduce((a, b) => a + b) / classMarks.length;
        reports.add(_ClassReportItem(
          grade: assignment.grade,
          className: assignment.className,
          averageOutOfTen: average,
          lowStudents: lows,
        ));
      }

      setState(() {
        _classReports = reports;
        _loadingTeacherReport = false;
      });
    } catch (e) {
      setState(() {
        _teacherReportError = "unableToBuildTeacherReport".tr;
        _loadingTeacherReport = false;
      });
      debugPrint("Teacher report build failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Scaffold(
        appBar: PreferredSize(
            preferredSize: const Size(double.infinity, 50),
            child: isMobile ? MyAppBar("") : const SizedBox()),
        body: Stack(
          children: [
            isMobile ? const SizedBox() : const BackButtonWidget(),
            Padding(
              padding: EdgeInsets.only(
                  top: isMobile ? 5 : 30,
                  left: isMobile ? 12 : 100,
                  right: isMobile ? 12 : 30),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "reports".tr,
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: 18,
                          color: themeManager.isHighContrast
                              ? AppColor.white
                              : AppColor.buttonGreen),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _teacherPerformanceSection(themeManager),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _teacherPerformanceSection(ThemeManager themeManager) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow, blurRadius: 5, offset: Offset(0, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "teacherClassReportTitle".tr,
              style: NotoSansArabicCustomTextStyle.semibold
                  .copyWith(fontSize: 16, color: AppColor.black),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              hint: Text("selectTeacherHint".tr),
              items: _teacherOptions
                  .map((t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _loadingTeachers
                  ? null
                  : (value) async {
                      if (value == null) return;
                      setState(() {
                        _selectedTeacherId = value;
                      });
                      await _buildTeacherClassReport(value);
                    },
            ),
            if (_loadingTeachers) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 10),
            if (_teacherOptions.isEmpty && !_loadingTeachers)
              Text(
                "noTeachersFound".tr,
                style: NotoSansArabicCustomTextStyle.regular
                    .copyWith(color: AppColor.textGrey),
              ),
            if (_teacherOptions.isNotEmpty &&
                _selectedTeacherId == null &&
                !_loadingTeachers)
              Text(
                "selectTeacherToViewReport".tr,
                style: NotoSansArabicCustomTextStyle.regular
                    .copyWith(color: AppColor.textGrey),
              ),
            if (_teacherOptions.isNotEmpty &&
                _selectedTeacherId != null &&
                _teacherReportError != null)
              Text(
                _teacherReportError!,
                style: NotoSansArabicCustomTextStyle.regular
                    .copyWith(color: Colors.red.shade700),
              ),
            if (_teacherOptions.isNotEmpty &&
                _selectedTeacherId != null &&
                _loadingTeacherReport)
              const Center(child: CircularProgressIndicator()),
            if (_teacherOptions.isNotEmpty &&
                _selectedTeacherId != null &&
                !_loadingTeacherReport &&
                _teacherReportError == null)
              _classReports.isEmpty
                  ? Text(
                      "noClassReportDataForSelectedTeacher".tr,
                      style: NotoSansArabicCustomTextStyle.regular
                          .copyWith(color: AppColor.black),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _classReports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = _classReports[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColor.lightGrey),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${c.grade} - ${c.className}",
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: 15, color: AppColor.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${"averageMarkLabel".tr} ${c.averageOutOfTen == null ? "-" : c.averageOutOfTen!.toStringAsFixed(2)} / 10",
                                  style: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 13, color: AppColor.black),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "studentsBelowSixLastEntry".tr,
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: 13, color: AppColor.black),
                                ),
                                const SizedBox(height: 4),
                                c.lowStudents.isEmpty
                                    ? Text(
                                        "noneLabel".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .regular
                                            .copyWith(
                                                fontSize: 12,
                                                color: AppColor.textGrey),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: c.lowStudents
                                            .map(
                                              (s) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 2),
                                                child: Text(
                                                  "${s.studentName} (${s.subject}) - ${s.markOutOfTen.toStringAsFixed(2)}/10",
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .regular
                                                          .copyWith(
                                                              fontSize: 12,
                                                              color: AppColor
                                                                  .black),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ],
        ),
      ),
    );
  }
}

class _TeacherOption {
  final String id;
  final String name;
  final Map<dynamic, dynamic> assignedGrades;

  _TeacherOption({
    required this.id,
    required this.name,
    required this.assignedGrades,
  });
}

class _ClassAssignment {
  final String grade;
  final String className;
  final List<String> subjects;

  _ClassAssignment({
    required this.grade,
    required this.className,
    required this.subjects,
  });
}

class _ClassReportItem {
  final String grade;
  final String className;
  final double? averageOutOfTen;
  final List<_LowStudentMark> lowStudents;

  _ClassReportItem({
    required this.grade,
    required this.className,
    required this.averageOutOfTen,
    required this.lowStudents,
  });
}

class _LowStudentMark {
  final String studentId;
  final String studentName;
  final String subject;
  final double markOutOfTen;

  _LowStudentMark({
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.markOutOfTen,
  });
}
