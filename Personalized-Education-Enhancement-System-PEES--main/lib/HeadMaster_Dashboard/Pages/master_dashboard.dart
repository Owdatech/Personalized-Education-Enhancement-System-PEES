// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/API_SERVICES/preference_manager.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/headMaster_model.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/reports_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/user_model.dart';
import 'package:pees/Parent_Dashboard/Pages/alerts&Noti_Screen.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/AppSection.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard> {
  static const int _schoolMetricsWindowDays = 30;
  HeadMasterServices viewModel = HeadMasterServices();
  String? userId;
  String? _selectedGradeForSubjects;

  List<dynamic> metrics = [];
  bool _loadingMetrics = false;
  String? _metricsError;

  String? _extractStudentId(dynamic student) {
    if (student is! Map) return null;
    final map = student.cast<dynamic, dynamic>();
    final id = map['studentId'] ?? map['student_id'] ?? map['id'];
    final text = id?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  String _extractStudentGrade(dynamic student, {String fallback = "Unknown"}) {
    if (student is! Map) return fallback;
    final map = student.cast<dynamic, dynamic>();
    final grade = map['grade'] ?? map['gradeName'];
    final text = grade?.toString().trim();
    return (text == null || text.isEmpty) ? fallback : text;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  double _roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  DateTime? _parseAnyDate(dynamic raw) {
    if (raw == null) return null;

    if (raw is num) {
      final value = raw.toInt();
      final ms = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }

    if (raw is! String) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso.toLocal();

    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(text);
    if (dmy != null) {
      final day = int.tryParse(dmy.group(1)!);
      final month = int.tryParse(dmy.group(2)!);
      final year = int.tryParse(dmy.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  DateTime? _extractHistoryDate(Map<dynamic, dynamic> item) {
    const keys = [
      'date',
      'examDate',
      'exam_date',
      'createdAt',
      'created_at',
      'updatedAt',
      'updated_at',
      'timestamp',
    ];

    for (final key in keys) {
      if (!item.containsKey(key)) continue;
      final parsed = _parseAnyDate(item[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool _isWithinLastDays(DateTime date, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(start) && !target.isAfter(today);
  }

  String _formatChartValue(double value) {
    return value.toStringAsFixed(2);
  }

  int _extractGradeOrder(String gradeText) {
    final normalized = gradeText.toUpperCase().replaceAll('_', ' ');
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (match == null) return 999; // Unknown grades go last.
    return int.tryParse(match.group(1)!) ?? 999;
  }

  void _sortMetricsByGrade(List<dynamic> items) {
    items.sort((a, b) {
      final aMap = a is Map ? a.cast<dynamic, dynamic>() : <dynamic, dynamic>{};
      final bMap = b is Map ? b.cast<dynamic, dynamic>() : <dynamic, dynamic>{};

      final aGrade = (aMap['grade'] ?? '').toString().trim();
      final bGrade = (bMap['grade'] ?? '').toString().trim();
      final aOrder = _extractGradeOrder(aGrade);
      final bOrder = _extractGradeOrder(bGrade);

      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return aGrade.compareTo(bGrade);
    });
  }

  List<_GradeChartPoint> _buildGradeChartData() {
    final List<_GradeChartPoint> points = [];

    for (final metric in metrics) {
      final metricItem = metric is Map
          ? metric.cast<dynamic, dynamic>()
          : <dynamic, dynamic>{};
      final grade = (metricItem['grade'] ?? 'Unknown').toString().trim();
      final dynamic subjectsRaw = metricItem['subjects'];
      final Map<String, dynamic> subjects = subjectsRaw is Map
          ? subjectsRaw.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};

      double sum = 0;
      int count = 0;
      for (final entry in subjects.entries) {
        final markText =
            _resolveSubjectAverageMark(metricItem, entry.key, entry.value);
        final mark = double.tryParse(markText);
        if (mark != null) {
          sum += mark;
          count += 1;
        }
      }

      if (count > 0) {
        points.add(_GradeChartPoint(
          grade: grade,
          averageMark: _roundToTwoDecimals(sum / count),
          order: _extractGradeOrder(grade),
        ));
      }
    }

    points.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      return a.grade.compareTo(b.grade);
    });
    return points;
  }

  List<String> _availableGradesFromMetrics() {
    final grades = metrics
        .map((m) => m is Map ? (m['grade'] ?? '').toString().trim() : '')
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    grades.sort((a, b) {
      final aOrder = _extractGradeOrder(a);
      final bOrder = _extractGradeOrder(b);
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return a.compareTo(b);
    });
    return grades;
  }

  List<_SubjectChartPoint> _buildSubjectChartDataForGrade(String grade) {
    final metricItem = metrics
        .whereType<Map>()
        .map((m) => m.cast<dynamic, dynamic>())
        .firstWhere(
          (m) => (m['grade'] ?? '').toString().trim() == grade,
          orElse: () => <dynamic, dynamic>{},
        );

    if (metricItem.isEmpty) return <_SubjectChartPoint>[];
    final dynamic subjectsRaw = metricItem['subjects'];
    final Map<String, dynamic> subjects = subjectsRaw is Map
        ? subjectsRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final points = <_SubjectChartPoint>[];
    for (final entry in subjects.entries) {
      final mark =
          _resolveSubjectAverageMark(metricItem, entry.key, entry.value);
      final numeric = double.tryParse(mark);
      if (numeric != null) {
        points.add(_SubjectChartPoint(
            subject: entry.key, averageMark: _roundToTwoDecimals(numeric)));
      }
    }
    points.sort((a, b) => a.subject.compareTo(b.subject));
    return points;
  }

  Future<List<dynamic>> _fetchStudentsList() async {
    final response = await http.get(
      Uri.parse("${Config.baseURL}students/list"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("students/list failed (${response.statusCode})");
    }

    final decoded = json.decode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['students'] is List) {
      return List<dynamic>.from(decoded['students']);
    }
    return <dynamic>[];
  }

  Future<List<dynamic>> _buildMetricsFromReportCards() async {
    final students = await _fetchStudentsList();
    if (students.isEmpty) return <dynamic>[];

    final Map<String, Map<String, List<double>>> gradeSubjectMarks = {};

    Future<void> processStudent(dynamic student) async {
      final studentId = _extractStudentId(student);
      if (studentId == null) return;

      final reportResponse = await http.get(
        Uri.parse('${Config.baseURL}api/student/report-card/$studentId'),
        headers: {"Content-Type": "application/json"},
      );

      if (reportResponse.statusCode != 200) return;
      final data = json.decode(reportResponse.body);
      if (data is! Map) return;

      final academicData = data['academicData'];
      if (academicData is! Map) return;

      final gradeFromReport = academicData['grade']?.toString().trim();
      final grade = (gradeFromReport != null && gradeFromReport.isNotEmpty)
          ? gradeFromReport
          : _extractStudentGrade(student);

      final subjects = academicData['subjects'];
      if (subjects is! Map) return;

      for (final entry in subjects.entries) {
        final subjectName = entry.key.toString().trim();
        if (subjectName.isEmpty) continue;

        final details = entry.value;
        if (details is! Map) continue;

        final history = details['history'];
        if (history is! List || history.isEmpty) continue;

        for (final item in history) {
          if (item is! Map) continue;
          final historyItem = item.cast<dynamic, dynamic>();
          final historyDate = _extractHistoryDate(historyItem);
          if (historyDate == null ||
              !_isWithinLastDays(historyDate, _schoolMetricsWindowDays)) {
            continue;
          }

          final marks = _asDouble(historyItem['marks']);
          if (marks == null) continue;

          gradeSubjectMarks
              .putIfAbsent(grade, () => {})
              .putIfAbsent(subjectName, () => [])
              .add(marks);
        }
      }
    }

    await Future.wait(students.map(processStudent));

    final List<dynamic> builtMetrics = [];
    for (final gradeEntry in gradeSubjectMarks.entries) {
      final Map<String, dynamic> subjectsAvg = {};
      for (final subjectEntry in gradeEntry.value.entries) {
        final values = subjectEntry.value;
        if (values.isEmpty) continue;
        final sum = values.fold<double>(0, (a, b) => a + b);
        final avg = sum / values.length;
        subjectsAvg[subjectEntry.key] = avg;
      }

      builtMetrics.add({
        "grade": gradeEntry.key,
        "subjects": subjectsAvg,
      });
    }

    _sortMetricsByGrade(builtMetrics);
    return builtMetrics;
  }

  Future<void> fetchPerformanceData() async {
    setState(() {
      _loadingMetrics = true;
      _metricsError = null;
    });
    try {
      final frontendMetrics = await _buildMetricsFromReportCards();
      setState(() {
        metrics = frontendMetrics;
        final grades = _availableGradesFromMetrics();
        if (_selectedGradeForSubjects == null ||
            !grades.contains(_selectedGradeForSubjects)) {
          _selectedGradeForSubjects = grades.isNotEmpty ? grades.first : null;
        }
        _metricsError = null;
      });
    } catch (e) {
      setState(() {
        metrics = [];
        _metricsError = 'Unable to load metrics';
      });
      print("School performance fetch failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingMetrics = false;
        });
      }
    }
  }

  String _formatAverageMark(dynamic rawValue) {
    String normalizeDigits(String input) {
      const arabicIndic = {
        '٠': '0',
        '١': '1',
        '٢': '2',
        '٣': '3',
        '٤': '4',
        '٥': '5',
        '٦': '6',
        '٧': '7',
        '٨': '8',
        '٩': '9',
      };
      const easternArabicIndic = {
        '۰': '0',
        '۱': '1',
        '۲': '2',
        '۳': '3',
        '۴': '4',
        '۵': '5',
        '۶': '6',
        '۷': '7',
        '۸': '8',
        '۹': '9',
      };

      final buffer = StringBuffer();
      for (final ch in input.split('')) {
        buffer.write(arabicIndic[ch] ?? easternArabicIndic[ch] ?? ch);
      }
      return buffer.toString();
    }

    double? formatNumber(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final trimmed = normalizeDigits(value.trim());
        final direct = double.tryParse(trimmed);
        if (direct != null) return direct;

        // Handle values like "87%" or "A (87.5)"
        final match = RegExp(r'-?\d+([.,]\d+)?').firstMatch(trimmed);
        if (match != null) {
          return double.tryParse(match.group(0)!.replaceAll(',', '.'));
        }
      }
      return null;
    }

    double? extractNumeric(dynamic value) {
      final direct = formatNumber(value);
      if (direct != null) return direct;

      if (value is Map) {
        const preferredKeys = [
          'average_mark',
          'average_marks',
          'averageMark',
          'averageMarks',
          'avg_mark',
          'avg_marks',
          'avgMark',
          'avgMarks',
          'marks',
          'mark',
          'average',
          'avg',
          'percentage',
          'score',
          'value',
        ];

        for (final key in preferredKeys) {
          if (value.containsKey(key)) {
            final parsed = extractNumeric(value[key]);
            if (parsed != null) return parsed;
          }
        }
      }

      return null;
    }

    String toDisplay(double v) {
      return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    }

    if (rawValue == null) return "-";

    final numeric = extractNumeric(rawValue);
    if (numeric != null) {
      return toDisplay(numeric);
    }

    return "-";
  }

  dynamic _lookupBySubjectKey(
      Map<dynamic, dynamic> source, String subjectName) {
    if (source.containsKey(subjectName)) return source[subjectName];

    final normalized = subjectName.trim().toLowerCase();
    for (final entry in source.entries) {
      final key = entry.key.toString().trim().toLowerCase();
      if (key == normalized) return entry.value;
    }
    return null;
  }

  String _resolveSubjectAverageMark(Map<dynamic, dynamic> metricItem,
      String subjectName, dynamic subjectValue) {
    // 1) Try subject-level payload first.
    final fromSubject = _formatAverageMark(subjectValue);
    if (fromSubject != "-") return fromSubject;

    // 2) Try common top-level maps that may hold subject->average marks.
    const topLevelMapKeys = [
      'average_marks',
      'average_mark',
      'subject_average_marks',
      'subject_averages',
      'subjectAverages',
      'averages',
      'marks',
    ];

    for (final key in topLevelMapKeys) {
      final candidate = metricItem[key];
      if (candidate is Map) {
        final subjectMapped = _lookupBySubjectKey(candidate, subjectName);
        final formatted = _formatAverageMark(subjectMapped);
        if (formatted != "-") return formatted;
      }
    }

    return "-";
  }

  String _extractGradeSymbol(dynamic rawValue) {
    if (rawValue == null) return "-";
    if (rawValue is String) {
      final v = rawValue.trim();
      return v.isEmpty ? "-" : v;
    }
    if (rawValue is Map) {
      const keys = ['average_grade', 'grade', 'avg_grade', 'value'];
      for (final key in keys) {
        if (rawValue.containsKey(key) && rawValue[key] != null) {
          final v = rawValue[key].toString().trim();
          if (v.isNotEmpty) return v;
        }
      }
    }
    return "-";
  }

  @override
  void initState() {
    fetchPerformanceData();
    loadUser();
    super.initState();
  }

  loadUser() async {
    AIUser? users = await PreferencesManager.shared.loadUser();
    userId = users?.userId;
    print("User Ids : ${users?.userId}");
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isMobile ? 12 : 20,
                                  right: isMobile ? 12 : 20,
                                  top: isMobile ? 12 : 20),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    isMobile
                                        ? Column(
                                            children: [
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 520),
                                                child: recentActivity(
                                                  "reports",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ReposrtsScreen()));
                                                  },
                                                ),
                                              ),
                                              // reports(),
                                              const SizedBox(height: 10),
                                              // alertsAndNotification(),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 520),
                                                child: recentActivity(
                                                  "alerts&Noti",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                AlertsNotificationScreen(
                                                                    isAlerts:
                                                                        false)));
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              schoolPerformance(isMobile),
                                              const SizedBox(height: 70),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 360,
                                                child: recentActivity(
                                                  "reports",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ReposrtsScreen()));
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              SizedBox(
                                                width: 360,
                                                child: recentActivity(
                                                  "alerts&Noti",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                AlertsNotificationScreen(
                                                                    isAlerts:
                                                                        false)));
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                    const SizedBox(height: 20),
                                    schoolPerformance(isMobile),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  value.loading ? LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget recentActivity(String title, VoidCallback onPressed) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return InkWell(
      onTap: () {
        onPressed();
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColor.greyShadow,
                  blurRadius: 5,
                  offset: Offset(0, 5))
            ],
            color: themeManager.isHighContrast
                ? AppColor.labelText
                : AppColor.white),
        child: Center(
            child: Text(
          title.tr,
          style: NotoSansArabicCustomTextStyle.medium.copyWith(
              fontSize: fontSizeProvider.fontSize, color: AppColor.black),
        )),
      ),
    );
  }

  Widget userManagement(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return InkWell(
      onTap: () {
        final headMasterServices =
            Provider.of<HeadMasterServices>(context, listen: false);
        headMasterServices.selectedIndex = 2; // Set index for User Management
        headMasterServices.notifyListeners();
      },
      child: Container(
        // width: 330,
        height: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColor.greyShadow,
                  blurRadius: 5,
                  offset: Offset(0, 5))
            ],
            color: themeManager.isHighContrast
                ? AppColor.labelText
                : AppColor.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "userManagement".tr,
              textAlign: TextAlign.center,
              style: NotoSansArabicCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          ],
        ),
      ),
    );
  }

  // Widget userManagement(bool isMobile) {
  //   final fontSizeProvider = Provider.of<FontSizeProvider>(context);
  //   final themeManager = Provider.of<ThemeManager>(context, listen: false);
  //   return Container(
  //     // width: 330,
  //     height: 280,
  //     decoration: BoxDecoration(
  //         color:
  //             themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
  //         borderRadius: BorderRadius.circular(5),
  //         boxShadow: const [
  //           BoxShadow(
  //               color: AppColor.greyShadow,
  //               blurRadius: 15,
  //               offset: Offset(0, 10))
  //         ]),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Container(
  //                 // height: 28,
  //                 decoration: const BoxDecoration(
  //                     borderRadius: BorderRadius.only(
  //                         topRight: Radius.circular(5),
  //                         topLeft: Radius.circular(5)),
  //                     color: AppColor.buttonGreen),
  //                 child: Padding(
  //                   padding: const EdgeInsets.only(top: 5, bottom: 5),
  //                   child: Text(
  //                     "userManagement".tr,
  //                     textAlign: TextAlign.center,
  //                     style: PoppinsCustomTextStyle.bold.copyWith(
  //                         fontSize: fontSizeProvider.fontSize,
  //                         color: AppColor.white),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(left: 8, top: 10),
  //           child: Column(
  //             children: [
  //               Text(
  //                 "userManagesubList".tr,
  //                 style: PoppinsCustomTextStyle.medium.copyWith(
  //                     fontSize: fontSizeProvider.fontSize,
  //                     color: AppColor.black),
  //               ),
  //               const SizedBox(height: 10),
  //               isMobile
  //                   ? AppFillButton2(
  //                       onPressed: () {
  //                         Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                                 builder: (context) =>
  //                                     UserManagementScreen()));
  //                       },
  //                       text: "userMange")
  //                   : AppFillButton2(
  //                       onPressed: () {
  //                         final headMasterServices =
  //                             Provider.of<HeadMasterServices>(context,
  //                                 listen: false);
  //                         headMasterServices.selectedIndex =
  //                             2; // Set index for User Management
  //                         headMasterServices.notifyListeners();
  //                         // Navigator.push(
  //                         //     context,
  //                         //     MaterialPageRoute(
  //                         //         builder: (context) => UserManagementScreen()));
  //                       },
  //                       text: "userMange")
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  Widget reports() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 330,
      height: 280,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  // height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      "reports".tr,
                      textAlign: TextAlign.center,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 10),
            child: Text(
              "reportssubList".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget alertsAndNotification() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return Container(
      // width: 330,
      height: 280,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  // height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      "alerts&Noti".tr,
                      textAlign: TextAlign.center,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 10),
            child: Text(
              "subAlert".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget schoolPerformance(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final chartData = _buildGradeChartData();
    final gradeOptions = _availableGradesFromMetrics();
    if (_selectedGradeForSubjects == null && gradeOptions.isNotEmpty) {
      _selectedGradeForSubjects = gradeOptions.first;
    }
    final subjectChartData = _selectedGradeForSubjects == null
        ? <_SubjectChartPoint>[]
        : _buildSubjectChartDataForGrade(_selectedGradeForSubjects!);
    return AppSection(
      title: "schoolperfo".tr,
      child: Container(
        height: 980,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "schoolPerformanceWindow30Days".tr,
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        fontSize: fontSizeProvider.fontSize - 1,
                        color: AppColor.textGrey),
                  ),
                ),
              ),
              Expanded(
                child: _loadingMetrics
                    ? const Center(child: CircularProgressIndicator())
                    : _metricsError != null
                        ? Center(
                            child: Text(_metricsError!,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(color: AppColor.black)),
                          )
                        : metrics.isEmpty
                            ? Center(
                                child: Text(
                                    "noSchoolPerformanceDataLast30Days".tr,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(color: AppColor.black)),
                              )
                            : ListView.builder(
                                itemCount: metrics.length,
                                itemBuilder: (context, index) {
                                  final item = metrics[index];
                                  final metricItem = item is Map
                                      ? item.cast<dynamic, dynamic>()
                                      : <dynamic, dynamic>{};
                                  final grade =
                                      metricItem['grade'] ?? 'Unknown';
                                  final dynamic subjectsRaw =
                                      metricItem['subjects'];
                                  final Map<String, dynamic> subjects =
                                      subjectsRaw is Map
                                          ? subjectsRaw.map((k, v) =>
                                              MapEntry(k.toString(), v))
                                          : <String, dynamic>{};
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: AppColor.white,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          boxShadow: const [
                                            BoxShadow(
                                                blurRadius: 5,
                                                color: AppColor.greyShadow,
                                                offset: Offset(0, 5))
                                          ]),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Text('${"grade".tr} : ',
                                                    style:
                                                        NotoSansArabicCustomTextStyle
                                                            .semibold
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black)),
                                                Text('$grade',
                                                    style:
                                                        NotoSansArabicCustomTextStyle
                                                            .regular
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black)),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('${"subject".tr} : ',
                                                    style:
                                                        NotoSansArabicCustomTextStyle
                                                            .semibold
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black)),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: subjects.entries
                                                        .map((e) {
                                                      final mark =
                                                          _resolveSubjectAverageMark(
                                                              metricItem,
                                                              e.key,
                                                              e.value);
                                                      if (mark != "-") {
                                                        return Text(
                                                            "${e.key} - Average Marks : $mark");
                                                      }
                                                      final gradeSymbol =
                                                          _extractGradeSymbol(
                                                              e.value);
                                                      return Text(
                                                          "${e.key} - Average Grade : $gradeSymbol");
                                                    }).toList(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              if (chartData.isNotEmpty) const SizedBox(height: 12),
              if (chartData.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.lightGrey, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SfCartesianChart(
                      title: ChartTitle(
                        text: "performanceByGrade".tr,
                        textStyle: NotoSansArabicCustomTextStyle.semibold
                            .copyWith(
                                fontSize: fontSizeProvider.fontSize,
                                color: AppColor.black),
                      ),
                      primaryXAxis: CategoryAxis(
                        labelRotation: -35,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: const NumericAxis(
                        minimum: 0,
                        maximum: 10,
                        interval: 1,
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<_GradeChartPoint, String>>[
                        ColumnSeries<_GradeChartPoint, String>(
                          dataSource: chartData,
                          xValueMapper: (_GradeChartPoint data, _) =>
                              data.grade,
                          yValueMapper: (_GradeChartPoint data, _) =>
                              data.averageMark,
                          dataLabelMapper: (_GradeChartPoint data, _) =>
                              _formatChartValue(data.averageMark),
                          color: AppColor.buttonGreen,
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ),
              if (chartData.isNotEmpty) const SizedBox(height: 12),
              if (chartData.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.lightGrey, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        LayoutBuilder(builder: (context, rowConstraints) {
                          final isNarrow = rowConstraints.maxWidth < 700;
                          final titleText =
                              "${"subjectsByGrade".tr} (${_selectedGradeForSubjects ?? '-'})";

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleText,
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black),
                                ),
                                if (gradeOptions.isNotEmpty)
                                  const SizedBox(height: 8),
                                if (gradeOptions.isNotEmpty)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: _selectedGradeForSubjects,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      items: gradeOptions
                                          .map((g) => DropdownMenuItem<String>(
                                                value: g,
                                                child: Text(g,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedGradeForSubjects = value;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titleText,
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black),
                                ),
                              ),
                              if (gradeOptions.isNotEmpty)
                                const SizedBox(width: 12),
                              if (gradeOptions.isNotEmpty)
                                SizedBox(
                                  height: 40,
                                  width: 220,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedGradeForSubjects,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                    items: gradeOptions
                                        .map((g) => DropdownMenuItem<String>(
                                              value: g,
                                              child: Text(g,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedGradeForSubjects = value;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 8),
                        Expanded(
                          child: subjectChartData.isEmpty
                              ? Center(
                                  child: Text(
                                    "noSubjectMarksForSelectedGrade".tr,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(color: AppColor.black),
                                  ),
                                )
                              : SfCartesianChart(
                                  primaryXAxis: CategoryAxis(
                                    labelRotation: -35,
                                    majorGridLines:
                                        const MajorGridLines(width: 0),
                                  ),
                                  primaryYAxis: const NumericAxis(
                                    minimum: 0,
                                    maximum: 10,
                                    interval: 1,
                                  ),
                                  tooltipBehavior:
                                      TooltipBehavior(enable: true),
                                  series: <CartesianSeries<_SubjectChartPoint,
                                      String>>[
                                    ColumnSeries<_SubjectChartPoint, String>(
                                      dataSource: subjectChartData,
                                      xValueMapper:
                                          (_SubjectChartPoint data, _) =>
                                              data.subject,
                                      yValueMapper:
                                          (_SubjectChartPoint data, _) =>
                                              data.averageMark,
                                      dataLabelMapper: (_SubjectChartPoint data,
                                              _) =>
                                          _formatChartValue(data.averageMark),
                                      color: Colors.teal,
                                      dataLabelSettings:
                                          const DataLabelSettings(
                                              isVisible: true),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  onTap(HeadMasterListType? type) {}
  Widget listItem(HeadMasterModel model, int index) {
    bool isSelected = index == viewModel.selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 15),
      child: InkWell(
        onTap: () {
          setState(() {
            onTap(model.type);
            viewModel.selectedIndex = index;
          });
        },
        child: Container(
          height: 73,
          width: 269,
          decoration: BoxDecoration(
              color: isSelected ? AppColor.buttonGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 10),
                    blurRadius: 15,
                    color:
                        isSelected ? AppColor.buttonShadow : Colors.transparent)
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 27),
              Image.asset(
                isSelected
                    ? model.colorImage.toString()
                    : model.fillImage.toString(),
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 22),
              Text(
                model.title.toString(),
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: 18,
                    color: isSelected ? AppColor.white : AppColor.textGrey),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeChartPoint {
  final String grade;
  final double averageMark;
  final int order;

  _GradeChartPoint({
    required this.grade,
    required this.averageMark,
    required this.order,
  });
}

class _SubjectChartPoint {
  final String subject;
  final double averageMark;

  _SubjectChartPoint({
    required this.subject,
    required this.averageMark,
  });
}
