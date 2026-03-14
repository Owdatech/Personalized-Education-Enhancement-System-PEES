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
  String? _selectedAbsenceMonthKey;

  List<dynamic> metrics = [];
  Map<String, Map<String, int>> _absenceCountsByMonthAndGrade = {};
  bool _loadingMetrics = false;
  String? _metricsError;

  static const Color _bgLavender = Color(0xFFD9D6F5);
  static const Color _panelDark = Color(0xFF11131A);
  static const Color _panelDarkSoft = Color(0xFF171A22);
  static const Color _textLight = Color(0xFFF3F2FF);
  static const Color _textMuted = Color(0xFFB2B6C6);

  BoxDecoration _glassPanelDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _panelDark.withOpacity(0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF2A2E3A), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        )
      ],
    );
  }

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
    final gradeCandidates = [
      map['grade'],
      map['gradeName'],
      map['grade_ref'],
      map['gradeRef'],
    ];
    for (final candidate in gradeCandidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text.replaceFirst(RegExp(r'^ref_to_', caseSensitive: false), '');
      }
    }
    return fallback;
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

  double _toPercentage(double marks, double? totalMarks) {
    if (totalMarks != null && totalMarks > 0) {
      return (marks / totalMarks) * 100.0;
    }
    if (marks >= 0 && marks <= 100) return marks;
    return marks;
  }

  String _formatChartValue(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  Color _scoreColor(double value) {
    if (value >= 80.0) return const Color(0xFF8E7CFF);
    if (value >= 60.0) return const Color(0xFF5C8DFF);
    if (value >= 40.0) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  int? _extractKgOrder(String gradeText) {
    final normalized = gradeText
        .toUpperCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (RegExp(r'\bKG\s*1\b').hasMatch(normalized) ||
        RegExp(r'\bKINDERGARTEN\s*1\b').hasMatch(normalized)) {
      return 1;
    }
    if (RegExp(r'\bKG\s*2\b').hasMatch(normalized) ||
        RegExp(r'\bKINDERGARTEN\s*2\b').hasMatch(normalized)) {
      return 2;
    }
    return null;
  }

  int _extractGradeOrder(String gradeText) {
    final kgOrder = _extractKgOrder(gradeText);
    if (kgOrder != null) return kgOrder - 1;
    final normalized = gradeText.toUpperCase().replaceAll('_', ' ');
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (match == null) return 999; // Unknown grades go last.
    final gradeNumber = int.tryParse(match.group(1)!);
    return gradeNumber == null ? 999 : gradeNumber + 1;
  }

  int _extractTrackOrder(String gradeText) {
    final normalized = gradeText.toUpperCase();
    if (normalized.contains('SCIENCE') || normalized.contains('(SC)')) return 0;
    if (normalized.contains('LITERATURE') || normalized.contains('(LI)')) {
      return 1;
    }
    return 2;
  }

  String _shortGradeLabel(String gradeText) {
    if (gradeText.trim().isEmpty) return gradeText;
    return gradeText
        .replaceAllMapped(
            RegExp(r'\(\s*SCIENCE\s*\)', caseSensitive: false), (_) => '(SC)')
        .replaceAllMapped(RegExp(r'\(\s*LITERATURE\s*\)', caseSensitive: false),
            (_) => '(LI)');
  }

  String _compactGradeForChart(String gradeText) {
    final canonical = _canonicalGrade(gradeText).toUpperCase();
    final kgOrder = _extractKgOrder(canonical);
    if (kgOrder != null) return 'KG$kgOrder';
    final numMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(canonical);
    if (numMatch == null) return _shortGradeLabel(gradeText);
    final n = numMatch.group(1)!;
    if (canonical.contains('SCIENCE')) return 'G$n-SC';
    if (canonical.contains('LITERATURE')) return 'G$n-LI';
    return 'G$n';
  }

  String _canonicalGrade(String gradeText) {
    final raw = gradeText.trim();
    if (raw.isEmpty) return raw;

    final normalized = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();

    final kgOrder = _extractKgOrder(normalized);
    if (kgOrder != null) return 'KG$kgOrder';
    final numMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (numMatch == null) return normalized;

    final gradeNumber = numMatch.group(1)!;
    final hasScience = RegExp(r'\bSCIENCE\b').hasMatch(normalized);
    final hasLiterature = RegExp(r'\bLITERATURE\b').hasMatch(normalized);

    if (hasScience) return 'GRADE $gradeNumber(SCIENCE)';
    if (hasLiterature) return 'GRADE $gradeNumber(LITERATURE)';
    return 'GRADE $gradeNumber';
  }

  bool _isSeniorGradeWithoutTrack(String gradeText) {
    final canonical = _canonicalGrade(gradeText).toUpperCase();
    final numMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(canonical);
    if (numMatch == null) return false;
    final n = int.tryParse(numMatch.group(1) ?? '');
    if (n == null || (n != 11 && n != 12)) return false;
    return !canonical.contains('SCIENCE') && !canonical.contains('LITERATURE');
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
      final aTrackOrder = _extractTrackOrder(aGrade);
      final bTrackOrder = _extractTrackOrder(bGrade);
      if (aTrackOrder != bTrackOrder) {
        return aTrackOrder.compareTo(bTrackOrder);
      }
      return aGrade.compareTo(bGrade);
    });
  }

  double? _parseDisplayedAverageMark(String text) {
    final cleaned = text.replaceAll('%', '').trim();
    return double.tryParse(cleaned);
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
        final mark = _parseDisplayedAverageMark(markText);
        if (mark != null) {
          sum += mark;
          count += 1;
        }
      }

      points.add(_GradeChartPoint(
        grade: grade,
        averageMark: count > 0 ? _roundToTwoDecimals(sum / count) : 0,
        order: _extractGradeOrder(grade),
      ));
    }

    points.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      final aTrackOrder = _extractTrackOrder(a.grade);
      final bTrackOrder = _extractTrackOrder(b.grade);
      if (aTrackOrder != bTrackOrder) {
        return aTrackOrder.compareTo(bTrackOrder);
      }
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
      final aTrackOrder = _extractTrackOrder(a);
      final bTrackOrder = _extractTrackOrder(b);
      if (aTrackOrder != bTrackOrder) {
        return aTrackOrder.compareTo(bTrackOrder);
      }
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
      final numeric = _parseDisplayedAverageMark(mark);
      if (numeric != null) {
        points.add(_SubjectChartPoint(
            subject: entry.key, averageMark: _roundToTwoDecimals(numeric)));
      }
    }
    points.sort((a, b) => a.subject.compareTo(b.subject));
    return points;
  }

  String? _firstGradeWithSubjectData(List<String> gradeOptions) {
    for (final grade in gradeOptions) {
      if (_buildSubjectChartDataForGrade(grade).isNotEmpty) {
        return grade;
      }
    }
    return gradeOptions.isNotEmpty ? gradeOptions.first : null;
  }

  bool _shouldExcludeMetricsSubject(String subjectName) {
    final normalized = subjectName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized == 'e2e' ||
        normalized == 'local_temp_subject_e2e' ||
        normalized.endsWith('_e2e');
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return monthKey;
    }

    const monthNamesEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const monthNamesAr = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final monthName = (isArabic ? monthNamesAr : monthNamesEn)[month - 1];
    return '$monthName $year';
  }

  List<String> _availableAbsenceMonths() {
    final months = _absenceCountsByMonthAndGrade.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  DateTime? _extractObservationDate(Map<dynamic, dynamic> item) {
    const keys = [
      'date',
      'selectedDate',
      'selected_date',
      'observationDate',
      'observation_date',
      'entryDate',
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
    return _extractHistoryDate(item);
  }

  bool _isObservationMarkedAbsent(Map<dynamic, dynamic> item) {
    final rawObservation = item['observation']?.toString() ?? '';
    if (rawObservation.trim().isEmpty) return false;

    final englishAbsent = RegExp(
      r'(^|\n)\s*Attendance\s*:\s*Absent\b',
      caseSensitive: false,
      multiLine: true,
    );
    final arabicAbsent = RegExp(
      r'(^|\n)\s*(حضور|الحضور)\s*:\s*(غائب|غائبة|غياب)\b',
      multiLine: true,
    );

    return englishAbsent.hasMatch(rawObservation) ||
        arabicAbsent.hasMatch(rawObservation);
  }

  Future<Map<String, Map<String, int>>> _buildAbsenceCountsFromObservations(
      List<dynamic> students) async {
    final Set<String> uniqueAbsences = <String>{};

    Future<void> processStudent(dynamic student) async {
      final studentId = _extractStudentId(student);
      if (studentId == null) return;

      final grade = _canonicalGrade(_extractStudentGrade(student));
      if (grade.isEmpty) return;

      final response = await http.get(
        Uri.parse('${Config.baseURL}students/$studentId/observations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      final observations = decoded is Map && decoded['observations'] is List
          ? List<dynamic>.from(decoded['observations'])
          : <dynamic>[];

      for (final entry in observations) {
        if (entry is! Map) continue;
        final item = entry.cast<dynamic, dynamic>();
        if (!_isObservationMarkedAbsent(item)) continue;

        final date = _extractObservationDate(item);
        if (date == null) continue;

        final uniqueKey =
            '${_monthKey(date)}|$grade|$studentId|${_dayKey(date)}';
        uniqueAbsences.add(uniqueKey);
      }
    }

    await Future.wait(students.map(processStudent));

    final Map<String, Map<String, int>> counts = {};
    for (final uniqueKey in uniqueAbsences) {
      final parts = uniqueKey.split('|');
      if (parts.length != 4) continue;
      final month = parts[0];
      final grade = parts[1];
      counts.putIfAbsent(month, () => <String, int>{});
      counts[month]![grade] = (counts[month]![grade] ?? 0) + 1;
    }

    counts.forEach((_, byGrade) {
      final sortedEntries = byGrade.entries.toList()
        ..sort((a, b) {
          final aOrder = _extractGradeOrder(a.key);
          final bOrder = _extractGradeOrder(b.key);
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          final aTrackOrder = _extractTrackOrder(a.key);
          final bTrackOrder = _extractTrackOrder(b.key);
          if (aTrackOrder != bTrackOrder) {
            return aTrackOrder.compareTo(bTrackOrder);
          }
          return a.key.compareTo(b.key);
        });
      byGrade
        ..clear()
        ..addEntries(sortedEntries);
    });

    return counts;
  }

  List<_AbsenceChartPoint> _buildAbsenceChartData(String monthKey) {
    final gradeCounts =
        _absenceCountsByMonthAndGrade[monthKey] ?? <String, int>{};
    final points = gradeCounts.entries
        .map((entry) => _AbsenceChartPoint(
              grade: entry.key,
              absenceCount: entry.value,
              order: _extractGradeOrder(entry.key),
            ))
        .toList();

    points.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      final aTrackOrder = _extractTrackOrder(a.grade);
      final bTrackOrder = _extractTrackOrder(b.grade);
      if (aTrackOrder != bTrackOrder) {
        return aTrackOrder.compareTo(bTrackOrder);
      }
      return a.grade.compareTo(b.grade);
    });

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

  Future<List<dynamic>> _buildMetricsFromReportCards(
      List<dynamic> students) async {
    if (students.isEmpty) return <dynamic>[];

    final Map<String, Map<String, List<double>>> gradeSubjectMarks = {};
    final Set<String> allGrades = <String>{};

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

      final gradeFromReport = academicData['grade']?.toString().trim() ?? '';
      final gradeFromStudent = _extractStudentGrade(student);
      final reportCanonical = _canonicalGrade(gradeFromReport);
      final studentCanonical = _canonicalGrade(gradeFromStudent);

      // Keep Grade 11/12 split by stream using student grade when report grade is generic.
      final canonicalGrade = (reportCanonical.isNotEmpty &&
              !_isSeniorGradeWithoutTrack(reportCanonical))
          ? reportCanonical
          : studentCanonical;
      if (canonicalGrade.isNotEmpty) {
        allGrades.add(canonicalGrade);
      }

      final subjects = academicData['subjects'];
      if (subjects is! Map) return;

      for (final entry in subjects.entries) {
        final subjectName = entry.key.toString().trim();
        if (subjectName.isEmpty || _shouldExcludeMetricsSubject(subjectName)) {
          continue;
        }

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
          final totalMarks = _asDouble(historyItem['totalMark']);
          final percentage = _toPercentage(marks, totalMarks);

          gradeSubjectMarks
              .putIfAbsent(canonicalGrade, () => {})
              .putIfAbsent(subjectName, () => [])
              .add(percentage);
        }
      }
    }

    await Future.wait(students.map(processStudent));

    final List<dynamic> builtMetrics = [];
    final mergedGrades = <String>{...allGrades, ...gradeSubjectMarks.keys};
    final sortedGrades = mergedGrades.toList()
      ..sort((a, b) {
        final aOrder = _extractGradeOrder(a);
        final bOrder = _extractGradeOrder(b);
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aTrackOrder = _extractTrackOrder(a);
        final bTrackOrder = _extractTrackOrder(b);
        if (aTrackOrder != bTrackOrder) {
          return aTrackOrder.compareTo(bTrackOrder);
        }
        return a.compareTo(b);
      });
    for (final grade in sortedGrades) {
      final gradeSubjects =
          gradeSubjectMarks[grade] ?? <String, List<double>>{};
      final Map<String, dynamic> subjectsAvg = {};
      for (final subjectEntry in gradeSubjects.entries) {
        if (_shouldExcludeMetricsSubject(subjectEntry.key)) continue;
        final values = subjectEntry.value;
        if (values.isEmpty) continue;
        final sum = values.fold<double>(0, (a, b) => a + b);
        final avg = sum / values.length;
        subjectsAvg[subjectEntry.key] = avg;
      }

      builtMetrics.add({
        "grade": grade,
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
      final students = await _fetchStudentsList();
      final frontendMetrics = await _buildMetricsFromReportCards(students);
      final absenceCounts = await _buildAbsenceCountsFromObservations(students);
      setState(() {
        metrics = frontendMetrics;
        _absenceCountsByMonthAndGrade = absenceCounts;
        final grades = _availableGradesFromMetrics();
        if (_selectedGradeForSubjects == null ||
            !grades.contains(_selectedGradeForSubjects)) {
          _selectedGradeForSubjects = _firstGradeWithSubjectData(grades);
        }
        final months = _availableAbsenceMonths();
        if (_selectedAbsenceMonthKey == null ||
            !months.contains(_selectedAbsenceMonthKey)) {
          _selectedAbsenceMonthKey = months.isNotEmpty ? months.first : null;
        }
        _metricsError = null;
      });
    } catch (e) {
      setState(() {
        metrics = [];
        _absenceCountsByMonthAndGrade = {};
        _selectedAbsenceMonthKey = null;
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
      return '${v.toStringAsFixed(1)}%';
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
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: _bgLavender,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD9D6F5), Color(0xFFC9C3EE)],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1650),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: isMobile ? 12 : 18,
                            right: isMobile ? 12 : 18,
                            top: isMobile ? 12 : 18),
                        child: Container(
                          decoration: _glassPanelDecoration(radius: 26),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16, vertical: 16),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  isMobile
                                      ? Column(
                                          children: [
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
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
                                            const SizedBox(height: 10),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
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
                                            const SizedBox(height: 14),
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
                                  schoolPerformance(isMobile),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  value.loading ? LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget recentActivity(String title, VoidCallback onPressed) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return InkWell(
        onTap: () {
          onPressed();
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2D3241), width: 1),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1D27), Color(0xFF12141C)],
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8))
              ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF262A36),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    title == "reports"
                        ? Icons.auto_graph
                        : Icons.notification_add,
                    color: _textLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title.tr,
                    style: NotoSansArabicCustomTextStyle.medium.copyWith(
                        fontSize: fontSizeProvider.fontSize + 1,
                        color: _textLight),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: _textMuted)
              ],
            ),
          ),
        ));
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
        ));
  }

  // Widget userManagement(bool isMobile) {
  //   final fontSizeProvider = Provider.of<FontSizeProvider>(context);
  //   final themeManager = Provider.of<ThemeManager>(context, listen: false);
  //   return Container(
  //     // width: 330,
  //     height: 280,
  //     decoration: BoxDecoration(
  //         color:
  //             themeManager.isHighContrast ? AppColor.panelDarkSoft : AppColor.bgLavender,
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
          color: themeManager.isHighContrast
              ? AppColor.panelDarkSoft
              : AppColor.bgLavender,
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
          ),
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
          color: themeManager.isHighContrast
              ? AppColor.panelDarkSoft
              : AppColor.bgLavender,
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
          ),
        ],
      ),
    );
  }

  Widget schoolPerformance(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final smallDropdownFont =
        (fontSizeProvider.fontSize - 2).clamp(11.0, 14.0).toDouble();
    final chartData = _buildGradeChartData();
    final gradeOptions = _availableGradesFromMetrics();
    if (_selectedGradeForSubjects == null && gradeOptions.isNotEmpty) {
      _selectedGradeForSubjects = _firstGradeWithSubjectData(gradeOptions);
    }
    final subjectChartData = _selectedGradeForSubjects == null
        ? <_SubjectChartPoint>[]
        : _buildSubjectChartDataForGrade(_selectedGradeForSubjects!);
    final absenceMonths = _availableAbsenceMonths();
    if (_selectedAbsenceMonthKey == null && absenceMonths.isNotEmpty) {
      _selectedAbsenceMonthKey = absenceMonths.first;
    }
    final absenceChartData = _selectedAbsenceMonthKey == null
        ? <_AbsenceChartPoint>[]
        : _buildAbsenceChartData(_selectedAbsenceMonthKey!);

    Widget buildSectionCard({
      required String title,
      Widget? subtitle,
      required Widget child,
    }) {
      return Container(
        width: double.infinity,
        decoration: _glassPanelDecoration(radius: 20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCC8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize + 4,
                        color: _textLight,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                subtitle,
              ],
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
    }

    final metricsWidget = SizedBox(
      height: isMobile ? 260 : 320,
      child: _loadingMetrics
          ? const Center(child: CircularProgressIndicator())
          : _metricsError != null
              ? Center(
                  child: Text(
                    _metricsError!,
                    style: NotoSansArabicCustomTextStyle.medium
                        .copyWith(color: _textLight),
                  ),
                )
              : metrics.isEmpty
                  ? Center(
                      child: Text(
                        "noSchoolPerformanceDataLast30Days".tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(color: _textLight),
                      ),
                    )
                  : ListView.builder(
                      itemCount: metrics.length,
                      itemBuilder: (context, index) {
                        final item = metrics[index];
                        final metricItem = item is Map
                            ? item.cast<dynamic, dynamic>()
                            : <dynamic, dynamic>{};
                        final grade = metricItem['grade'] ?? 'Unknown';
                        final gradeDisplay = _shortGradeLabel(grade.toString());
                        final dynamic subjectsRaw = metricItem['subjects'];
                        final Map<String, dynamic> subjects = subjectsRaw is Map
                            ? subjectsRaw
                                .map((k, v) => MapEntry(k.toString(), v))
                            : <String, dynamic>{};
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _panelDarkSoft,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 5,
                                  color: Color(0x22000000),
                                  offset: Offset(0, 5),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        '${"grade".tr} : ',
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                          fontSize: 15,
                                          color: _textLight,
                                        ),
                                      ),
                                      Text(
                                        gradeDisplay,
                                        style: NotoSansArabicCustomTextStyle
                                            .regular
                                            .copyWith(
                                          fontSize: 15,
                                          color: _textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${"subject".tr} : ',
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                          fontSize: 15,
                                          color: _textLight,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: subjects.entries.map((e) {
                                            final mark =
                                                _resolveSubjectAverageMark(
                                              metricItem,
                                              e.key,
                                              e.value,
                                            );
                                            if (mark != '-') {
                                              return Text(
                                                "${e.key} - ${"averageMarks".tr} : $mark",
                                                style:
                                                    NotoSansArabicCustomTextStyle
                                                        .regular
                                                        .copyWith(
                                                  fontSize: 14,
                                                  color: _textLight,
                                                ),
                                              );
                                            }
                                            final gradeSymbol =
                                                _extractGradeSymbol(e.value);
                                            return Text(
                                              "${e.key} - ${"averageGrade".tr} : $gradeSymbol",
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                fontSize: 14,
                                                color: _textLight,
                                              ),
                                            );
                                          }).toList()
                                            ..addAll(subjects.isEmpty
                                                ? [
                                                    Text(
                                                      "noMarksHistoryYet".tr,
                                                      style:
                                                          NotoSansArabicCustomTextStyle
                                                              .regular
                                                              .copyWith(
                                                        fontSize: 13,
                                                        color: _textMuted,
                                                      ),
                                                    )
                                                  ]
                                                : []),
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
    );

    final performanceByGradeWidget = chartData.isEmpty
        ? SizedBox(
            height: 260,
            child: Center(
              child: Text(
                "noSchoolPerformanceDataLast30Days".tr,
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(color: _textLight),
              ),
            ),
          )
        : Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: _panelDarkSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2E3A), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  labelRotation: -35,
                  labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  maximumLabelWidth: 90,
                  labelStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                    fontSize: fontSizeProvider.fontSize - 1,
                    color: _textMuted,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 20,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  title: AxisTitle(
                    text: "percentageLabel".tr,
                    textStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize - 1,
                      color: _textMuted,
                    ),
                  ),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y%',
                ),
                series: <CartesianSeries<_GradeChartPoint, String>>[
                  ColumnSeries<_GradeChartPoint, String>(
                    dataSource: chartData,
                    xValueMapper: (_GradeChartPoint data, _) =>
                        _compactGradeForChart(data.grade),
                    yValueMapper: (_GradeChartPoint data, _) =>
                        data.averageMark,
                    pointColorMapper: (_GradeChartPoint data, _) =>
                        _scoreColor(data.averageMark),
                    dataLabelMapper: (_GradeChartPoint data, _) =>
                        _formatChartValue(data.averageMark),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                    width: 0.55,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle:
                          NotoSansArabicCustomTextStyle.semibold.copyWith(
                        fontSize: fontSizeProvider.fontSize - 1,
                        color: _textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    final subjectsByGradeWidget = Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: _panelDarkSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2E3A), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, rowConstraints) {
                final isNarrow = rowConstraints.maxWidth < 700;
                final titleText =
                    "${"subjectsByGrade".tr} (${_selectedGradeForSubjects == null ? '-' : _shortGradeLabel(_selectedGradeForSubjects!)})";

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: _textLight,
                        ),
                      ),
                      if (gradeOptions.isNotEmpty) const SizedBox(height: 8),
                      if (gradeOptions.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedGradeForSubjects,
                            dropdownColor: const Color(0xFF1F2330),
                            style:
                                NotoSansArabicCustomTextStyle.medium.copyWith(
                              color: _textLight,
                              fontSize: smallDropdownFont,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1A1E2B),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF384055),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFFDCC8FF),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: gradeOptions
                                .map((g) => DropdownMenuItem<String>(
                                      value: g,
                                      child: Text(
                                        _shortGradeLabel(g),
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                          fontSize: smallDropdownFont,
                                          color: _textLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: _textLight,
                        ),
                      ),
                    ),
                    if (gradeOptions.isNotEmpty) const SizedBox(width: 12),
                    if (gradeOptions.isNotEmpty)
                      SizedBox(
                        height: 40,
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedGradeForSubjects,
                          dropdownColor: const Color(0xFF1F2330),
                          style: NotoSansArabicCustomTextStyle.medium.copyWith(
                            color: _textLight,
                            fontSize: smallDropdownFont,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1A1E2B),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFF384055)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFFDCC8FF)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: gradeOptions
                              .map((g) => DropdownMenuItem<String>(
                                    value: g,
                                    child: Text(
                                      _shortGradeLabel(g),
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                        fontSize: smallDropdownFont,
                                        color: _textLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: subjectChartData.isEmpty
                  ? Center(
                      child: Text(
                        "noSubjectMarksForSelectedGrade".tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(color: _textMuted),
                      ),
                    )
                  : SfCartesianChart(
                      backgroundColor: Colors.transparent,
                      plotAreaBorderWidth: 0,
                      primaryXAxis: CategoryAxis(
                        labelRotation: -30,
                        labelIntersectAction: AxisLabelIntersectAction.wrap,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                        maximumLabelWidth: 90,
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(width: 0),
                        labelStyle:
                            NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize - 1,
                          color: _textMuted,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 100,
                        interval: 20,
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(width: 0),
                        title: AxisTitle(
                          text: "percentageLabel".tr,
                          textStyle:
                              NotoSansArabicCustomTextStyle.regular.copyWith(
                            fontSize: fontSizeProvider.fontSize - 1,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'point.x : point.y%',
                      ),
                      series: <CartesianSeries<_SubjectChartPoint, String>>[
                        ColumnSeries<_SubjectChartPoint, String>(
                          dataSource: subjectChartData,
                          xValueMapper: (_SubjectChartPoint data, _) =>
                              data.subject,
                          yValueMapper: (_SubjectChartPoint data, _) =>
                              data.averageMark,
                          pointColorMapper: (_SubjectChartPoint data, _) =>
                              _scoreColor(data.averageMark),
                          dataLabelMapper: (_SubjectChartPoint data, _) =>
                              _formatChartValue(data.averageMark),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          width: 0.55,
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            textStyle:
                                NotoSansArabicCustomTextStyle.semibold.copyWith(
                              fontSize: fontSizeProvider.fontSize - 1,
                              color: _textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    final absenceByGradeWidget = Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: _panelDarkSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2E3A), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, rowConstraints) {
                final isNarrow = rowConstraints.maxWidth < 700;
                final selectedMonthLabel = _selectedAbsenceMonthKey == null
                    ? '-'
                    : _formatMonthLabel(_selectedAbsenceMonthKey!);
                final titleText =
                    '${"absenceByGrade".tr} ($selectedMonthLabel)';

                Widget monthDropdown() {
                  return SizedBox(
                    height: 40,
                    width: isNarrow ? double.infinity : 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedAbsenceMonthKey,
                      dropdownColor: const Color(0xFF1F2330),
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                        color: _textLight,
                        fontSize: smallDropdownFont,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1A1E2B),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF384055)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFFDCC8FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: absenceMonths
                          .map((monthKey) => DropdownMenuItem<String>(
                                value: monthKey,
                                child: Text(
                                  _formatMonthLabel(monthKey),
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(
                                    fontSize: smallDropdownFont,
                                    color: _textLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: absenceMonths.isEmpty
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedAbsenceMonthKey = value;
                              });
                            },
                    ),
                  );
                }

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: _textLight,
                        ),
                      ),
                      if (absenceMonths.isNotEmpty) const SizedBox(height: 8),
                      if (absenceMonths.isNotEmpty) monthDropdown(),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: _textLight,
                        ),
                      ),
                    ),
                    if (absenceMonths.isNotEmpty) const SizedBox(width: 12),
                    if (absenceMonths.isNotEmpty) monthDropdown(),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: absenceChartData.isEmpty
                  ? Center(
                      child: Text(
                        absenceMonths.isEmpty
                            ? 'noAbsenceDataAvailable'.tr
                            : 'noAbsenceDataForSelectedMonth'.tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(color: _textMuted),
                      ),
                    )
                  : SfCartesianChart(
                      backgroundColor: Colors.transparent,
                      plotAreaBorderWidth: 0,
                      primaryXAxis: CategoryAxis(
                        labelRotation: -35,
                        labelIntersectAction:
                            AxisLabelIntersectAction.multipleRows,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(width: 0),
                        maximumLabelWidth: 90,
                        labelStyle:
                            NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize - 1,
                          color: _textMuted,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        interval: 1,
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(width: 0),
                        title: AxisTitle(
                          text: 'absentStudentsCount'.tr,
                          textStyle:
                              NotoSansArabicCustomTextStyle.regular.copyWith(
                            fontSize: fontSizeProvider.fontSize - 1,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'point.x : point.y',
                      ),
                      series: <CartesianSeries<_AbsenceChartPoint, String>>[
                        ColumnSeries<_AbsenceChartPoint, String>(
                          dataSource: absenceChartData,
                          xValueMapper: (_AbsenceChartPoint data, _) =>
                              _compactGradeForChart(data.grade),
                          yValueMapper: (_AbsenceChartPoint data, _) =>
                              data.absenceCount,
                          color: const Color(0xFFFF6B8A),
                          dataLabelMapper: (_AbsenceChartPoint data, _) =>
                              data.absenceCount.toString(),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          width: 0.55,
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            textStyle:
                                NotoSansArabicCustomTextStyle.semibold.copyWith(
                              fontSize: fontSizeProvider.fontSize - 1,
                              color: _textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        buildSectionCard(
          title: "schoolperfo".tr,
          subtitle: Align(
            alignment: Directionality.of(context) == TextDirection.rtl
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              "schoolPerformanceWindow30Days".tr,
              style: NotoSansArabicCustomTextStyle.regular.copyWith(
                fontSize: fontSizeProvider.fontSize - 1,
                color: _textMuted,
              ),
            ),
          ),
          child: metricsWidget,
        ),
        const SizedBox(height: 12),
        buildSectionCard(
          title: "performanceByGrade".tr,
          child: performanceByGradeWidget,
        ),
        const SizedBox(height: 12),
        buildSectionCard(
          title: "subjectsByGrade".tr,
          child: subjectsByGradeWidget,
        ),
        const SizedBox(height: 12),
        buildSectionCard(
          title: "absenceByGrade".tr,
          child: absenceByGradeWidget,
        ),
      ],
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

class _AbsenceChartPoint {
  final String grade;
  final int absenceCount;
  final int order;

  _AbsenceChartPoint({
    required this.grade,
    required this.absenceCount,
    required this.order,
  });
}
