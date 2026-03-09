import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:pees/API_SERVICES/app_constant.dart/constant.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddObservationUniversalScreen extends StatefulWidget {
  const AddObservationUniversalScreen({super.key});

  @override
  State<AddObservationUniversalScreen> createState() =>
      _AddObservationUniversalScreenState();
}

class _AddObservationUniversalScreenState
    extends State<AddObservationUniversalScreen> {
  final TeacherService viewModel = TeacherService();
  final TextEditingController obsDateController = TextEditingController();
  final TextEditingController observationController = TextEditingController();

  final List<String> _behaviorOptions = const [
    'behaviorExcellentInteraction',
    'behaviorVeryGoodInteraction',
    'behaviorAcceptableInteraction',
    'behaviorWeakInteraction',
    'behaviorNoInteraction',
    'behaviorDisruptive',
    'behaviorLackOfFocus',
    'behaviorHomeworkNotDone',
  ];

  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  DateTime? _obsSelectedDate;
  html.File? file;
  bool loading = false;

  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  List<Curriculum> _allCurriculum = [];

  List<String> _gradeOptions = [];
  List<String> _subjectOptions = [];

  String? _selectedGrade;
  String? _selectedSubject;
  String? _selectedStudentId;
  String attendanceStatus = 'Present';
  String? selectedBehaviorInClass;

  @override
  void initState() {
    super.initState();
    _setObservationDateToToday();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      loading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) {
        return;
      }

      final studentsUrl =
          "${Config.baseURL}${ApiEndPoint.studentlist}?userId=$userId";
      final curriculumUrl =
          "${Config.curriculumBaseURL}curriculum?teacherId=$userId";

      final responses = await Future.wait([
        http.get(Uri.parse(studentsUrl), headers: {"Content-Type": "application/json"}),
        http.get(Uri.parse(curriculumUrl), headers: {"Content-Type": "application/json"}),
      ]);

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        if (data is List) {
          _allStudents = data.map((e) => StudentModel.fromJson(e)).toList();
        }
      }

      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        final List<dynamic> curriculumJson = data['curriculum'] ?? [];
        _allCurriculum =
            curriculumJson.map((json) => Curriculum.fromJson(json)).toList();
      }

      _initializeDropdowns();
    } catch (e) {
      debugPrint("Failed loading universal observation data: $e");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _initializeDropdowns() {
    final grades = <String>{};
    for (final s in _allStudents) {
      final g = (s.grade ?? "").trim();
      if (g.isNotEmpty) grades.add(g);
    }
    _gradeOptions = grades.toList();
    _gradeOptions.sort(_compareGrades);

    if (_gradeOptions.isNotEmpty) {
      _selectedGrade = _gradeOptions.first;
    } else {
      _selectedGrade = null;
    }

    _updateSubjectAndStudentByGrade(resetStudentSelection: true);
  }

  int _gradeVariantOrder(String normalized) {
    if (normalized.contains('SCIENCE') || normalized.contains('(SC)')) return 0;
    if (normalized.contains('LITERATURE') || normalized.contains('(LI)')) return 1;
    return 2;
  }

  int _extractGradeNumber(String normalized) {
    final match = RegExp(r'GRADE\s*[_-]?\s*(\d+)', caseSensitive: false)
        .firstMatch(normalized);
    if (match == null) return 999;
    return int.tryParse(match.group(1) ?? '') ?? 999;
  }

  int _compareGrades(String a, String b) {
    final aNorm = a.trim().toUpperCase().replaceAll('_', ' ');
    final bNorm = b.trim().toUpperCase().replaceAll('_', ' ');

    final aIsKg = aNorm.contains('KG1') || aNorm.contains('KG 1') || aNorm == 'KG';
    final bIsKg = bNorm.contains('KG1') || bNorm.contains('KG 1') || bNorm == 'KG';
    final aIsKg2 = aNorm.contains('KG2') || aNorm.contains('KG 2');
    final bIsKg2 = bNorm.contains('KG2') || bNorm.contains('KG 2');

    if (aIsKg && !bIsKg && !bIsKg2) return -1;
    if (bIsKg && !aIsKg && !aIsKg2) return 1;
    if (aIsKg2 && !bIsKg && !bIsKg2) return -1;
    if (bIsKg2 && !aIsKg && !aIsKg2) return 1;
    if (aIsKg && bIsKg2) return -1;
    if (aIsKg2 && bIsKg) return 1;

    final aNum = _extractGradeNumber(aNorm);
    final bNum = _extractGradeNumber(bNorm);
    if (aNum != bNum) return aNum.compareTo(bNum);

    final aVariant = _gradeVariantOrder(aNorm);
    final bVariant = _gradeVariantOrder(bNorm);
    if (aVariant != bVariant) return aVariant.compareTo(bVariant);

    return aNorm.compareTo(bNorm);
  }

  void _updateSubjectAndStudentByGrade({required bool resetStudentSelection}) {
    final selectedGrade = _selectedGrade;
    if (selectedGrade == null) {
      _subjectOptions = [];
      _selectedSubject = null;
      _filteredStudents = [];
      _selectedStudentId = null;
      return;
    }

    final subjects = _allCurriculum
        .where((e) => e.grade.toLowerCase().trim() == selectedGrade.toLowerCase().trim())
        .map((e) => e.subject.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _subjectOptions = subjects;
    if (_subjectOptions.isNotEmpty) {
      if (_selectedSubject == null || !_subjectOptions.contains(_selectedSubject)) {
        _selectedSubject = _subjectOptions.first;
      }
    } else {
      _selectedSubject = null;
    }

    _filteredStudents = _allStudents
        .where((s) =>
            (s.grade ?? "").trim().toLowerCase() == selectedGrade.trim().toLowerCase())
        .toList();
    _filteredStudents.sort((a, b) => (a.studentName ?? "")
        .toLowerCase()
        .compareTo((b.studentName ?? "").toLowerCase()));

    if (resetStudentSelection) {
      _selectedStudentId = null;
    } else if (_selectedStudentId != null &&
        !_filteredStudents.any((s) => s.studentId == _selectedStudentId)) {
      _selectedStudentId = null;
    }
  }

  void _setObservationDateToToday() {
    _obsSelectedDate = DateTime.now();
    obsDateController
      ..text = DateFormat('dd-MM-yyyy').format(_obsSelectedDate!)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: obsDateController.text.length),
      );
  }

  Future<void> _obsSelectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _obsSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
            colorScheme: const ColorScheme.dark(
              primary: AppColor.accentPrimary,
              onPrimary: Colors.white,
              surface: AppColor.panelDarkSoft,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColor.panelDarkSoft,
            dividerColor: AppColor.accentPrimary,
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: AppColor.panelDarkSoft,
              headerBackgroundColor: AppColor.panelDark,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStatePropertyAll(Colors.white),
              yearForegroundColor: WidgetStatePropertyAll(Colors.white),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColor.accentPrimary,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (newSelectedDate != null) {
      setState(() {
        _obsSelectedDate = newSelectedDate;
      });
      obsDateController
        ..text = DateFormat('dd-MM-yyyy').format(_obsSelectedDate!)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: obsDateController.text.length),
        );
    }
  }

  void _pickFiles() {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'application/pdf,image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          setState(() {
            file = files.first;
          });
        }
      });
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  Future<void> _saveObservation() async {
    if (_selectedGrade == null) {
      Utils.snackBar("pleaseSelectGrade".tr, context);
      return;
    }
    if (_selectedSubject == null || _selectedSubject!.trim().isEmpty) {
      Utils.snackBar("errorSubject".tr, context);
      return;
    }
    if (_selectedStudentId == null || _selectedStudentId!.trim().isEmpty) {
      Utils.snackBar("pleaseSelectStudent".tr, context);
      return;
    }
    final dateText = obsDateController.text.trim();
    if (dateText.isEmpty) {
      Utils.snackBar("Please select a date", context);
      return;
    }

    String observation = observationController.text.trim();
    if (observation.isEmpty &&
        attendanceStatus != 'Absent' &&
        (selectedBehaviorInClass == null ||
            selectedBehaviorInClass!.trim().isEmpty)) {
      Utils.snackBar("Please enter an observation", context);
      return;
    }

    if (observation.isEmpty && attendanceStatus == 'Absent') {
      observation = "absentAutoNote".tr;
    }

    if (!RegExp(r'^\s*(Selected Date|التاريخ المحدد):', caseSensitive: false)
        .hasMatch(observation)) {
      observation = "${"selectedDateLabel".tr}: $dateText\n$observation";
    }

    final localizedAttendanceValue =
        attendanceStatus == 'Absent' ? "absent".tr : "present".tr;
    if (!RegExp(r'^\s*(Attendance|حضور)\s*:', caseSensitive: false)
        .hasMatch(observation)) {
      observation =
          "${"attendance".tr}: $localizedAttendanceValue\n$observation";
    }

    if (selectedBehaviorInClass != null &&
        selectedBehaviorInClass!.trim().isNotEmpty &&
        _behaviorOptions.contains(selectedBehaviorInClass)) {
      final behaviorLinePattern = RegExp(
          r'^\s*(Behavior in Class|Behaviour in Class|سلوك الطالب في الصف)\s*:',
          caseSensitive: false);
      if (!behaviorLinePattern.hasMatch(observation)) {
        observation =
            "${"behaviorInClass".tr}: ${selectedBehaviorInClass!.tr}\n$observation";
      }
    }

    String apiDate = dateText;
    if (_obsSelectedDate != null) {
      apiDate = DateFormat('yyyy-MM-dd').format(_obsSelectedDate!);
    } else {
      try {
        apiDate = DateFormat('yyyy-MM-dd')
            .format(DateFormat('dd-MM-yyyy').parseStrict(dateText));
      } catch (_) {}
    }

    final code = await viewModel.addObservation(
      _selectedStudentId!,
      file,
      _selectedSubject!,
      observation,
      apiDate,
    );

    if (!mounted) return;
    if (code == 200) {
      Utils.snackBar("observationSavedSuccessfully".tr, context);
      setState(() {
        _selectedStudentId = null;
        observationController.clear();
        file = null;
      });
    } else {
      Utils.snackBar(viewModel.apiError ?? "Error: An unexpected error occurred", context);
    }
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? itemLabelBuilder,
  }) {
    final dropValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment:
          selectedLanguage == 'ar' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NotoSansArabicCustomTextStyle.medium
              .copyWith(color: AppColor.text, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColor.textField,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.lightGrey, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: dropValue,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hint,
                  style: NotoSansArabicCustomTextStyle.regular
                      .copyWith(color: AppColor.labelText, fontSize: 13),
                ),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 12, left: 6),
                child: Icon(Icons.keyboard_arrow_down, color: AppColor.textGrey),
              ),
              dropdownColor: AppColor.panelDarkSoft,
              style: NotoSansArabicCustomTextStyle.medium
                  .copyWith(color: AppColor.text, fontSize: 13),
              onChanged: onChanged,
              items: [
                ...items.map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          itemLabelBuilder?.call(e) ?? e,
                          style: NotoSansArabicCustomTextStyle.medium
                              .copyWith(color: AppColor.text, fontSize: 13),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    return Scaffold(
      backgroundColor: AppColor.bgLavender,
      body: Stack(
        children: [
          if (!isMobile) const BackButtonWidget(),
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 100, 24, isMobile ? 12 : 100, 24),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.panelDarkSoft,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        blurRadius: 15,
                        offset: Offset(0, 10),
                        color: AppColor.greyShadow)
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 26, vertical: isMobile ? 18 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) const BackButtonWidget(),
                      const SizedBox(height: 8),
                      Text(
                        "addNewObservation".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(color: AppColor.text, fontSize: 22),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(builder: (context, constraints) {
                        final twoCols = constraints.maxWidth >= 900;
                        if (twoCols) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: "grade".tr,
                                  hint: "selectGrade".tr,
                                  value: _selectedGrade,
                                  items: _gradeOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGrade = value;
                                      _updateSubjectAndStudentByGrade(
                                          resetStudentSelection: true);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildDropdown(
                                  label: "subject".tr,
                                  hint: "selectSubject".tr,
                                  value: _selectedSubject,
                                  items: _subjectOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSubject = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildDropdown(
                                  label: "student".tr,
                                  hint: "selectStudentName".tr,
                                  value: _selectedStudentId,
                                  items: _filteredStudents
                                      .map((e) => e.studentId ?? '')
                                      .where((e) => e.isNotEmpty)
                                      .toList(),
                                  itemLabelBuilder: (studentId) {
                                    final student = _filteredStudents.firstWhere(
                                      (s) => s.studentId == studentId,
                                      orElse: () => StudentModel(studentName: studentId),
                                    );
                                    return "${student.studentName ?? studentId} (${student.classSection ?? '-'})";
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStudentId = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildDropdown(
                              label: "grade".tr,
                              hint: "selectGrade".tr,
                              value: _selectedGrade,
                              items: _gradeOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGrade = value;
                                  _updateSubjectAndStudentByGrade(
                                      resetStudentSelection: true);
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              label: "subject".tr,
                              hint: "selectSubject".tr,
                              value: _selectedSubject,
                              items: _subjectOptions,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubject = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(
                              label: "student".tr,
                              hint: "selectStudentName".tr,
                              value: _selectedStudentId,
                              items: _filteredStudents
                                  .map((e) => e.studentId ?? '')
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              itemLabelBuilder: (studentId) {
                                final student = _filteredStudents.firstWhere(
                                  (s) => s.studentId == studentId,
                                  orElse: () => StudentModel(studentName: studentId),
                                );
                                return "${student.studentName ?? studentId} (${student.classSection ?? '-'})";
                              },
                              onChanged: (value) {
                                setState(() {
                                  _selectedStudentId = value;
                                });
                              },
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColor.panelDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "date".tr,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(color: AppColor.text),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 260,
                                  child: AppFillTextField(
                                      textController: obsDateController,
                                      readOnly: true,
                                      suffixIcon: IconButton(
                                          onPressed: () => _obsSelectDate(context),
                                          padding: const EdgeInsets.only(left: 15),
                                          icon: Image.asset(
                                            AppImage.calendar,
                                            width: 45,
                                          )),
                                      hintText: "selectDate".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: selectedLanguage == 'ar'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Directionality(
                                textDirection: selectedLanguage == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      "${"attendance".tr} :",
                                      style: NotoSansArabicCustomTextStyle.medium
                                          .copyWith(color: AppColor.text),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Present',
                                          groupValue: attendanceStatus,
                                          activeColor: AppColor.buttonGreen,
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              attendanceStatus = value;
                                              if (attendanceStatus == 'Absent') {
                                                selectedBehaviorInClass = null;
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          "present".tr,
                                          style: NotoSansArabicCustomTextStyle.medium
                                              .copyWith(color: AppColor.text),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Absent',
                                          groupValue: attendanceStatus,
                                          activeColor: AppColor.buttonGreen,
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              attendanceStatus = value;
                                              if (attendanceStatus == 'Absent') {
                                                selectedBehaviorInClass = null;
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          "absent".tr,
                                          style: NotoSansArabicCustomTextStyle.medium
                                              .copyWith(color: AppColor.text),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (attendanceStatus != 'Absent') ...[
                              const SizedBox(height: 12),
                              LayoutBuilder(builder: (context, constraints) {
                                final behaviorWidth = constraints.maxWidth > 620
                                    ? 360.0
                                    : constraints.maxWidth;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${"behaviorInClass".tr} :",
                                      style: NotoSansArabicCustomTextStyle.medium
                                          .copyWith(color: AppColor.text),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: behaviorWidth,
                                      child: Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColor.textField,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColor.lightGrey,
                                              width: 1),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _behaviorOptions.contains(
                                                    selectedBehaviorInClass)
                                                ? selectedBehaviorInClass
                                                : null,
                                            hint: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Text(
                                                "selectBehaviorInClass".tr,
                                                style:
                                                    NotoSansArabicCustomTextStyle
                                                        .regular
                                                        .copyWith(
                                                            color: AppColor
                                                                .labelText,
                                                            fontSize: 13),
                                              ),
                                            ),
                                            isExpanded: true,
                                            dropdownColor:
                                                AppColor.panelDarkSoft,
                                            icon: const Padding(
                                              padding: EdgeInsets.only(
                                                  right: 12, left: 6),
                                              child: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: AppColor.textGrey),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedBehaviorInClass = value;
                                              });
                                            },
                                            items: _behaviorOptions
                                                .map((behaviorKey) =>
                                                    DropdownMenuItem<String>(
                                                      value: behaviorKey,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12),
                                                        child: Text(
                                                          behaviorKey.tr,
                                                          style: NotoSansArabicCustomTextStyle
                                                              .medium
                                                              .copyWith(
                                                                  color: AppColor
                                                                      .text,
                                                                  fontSize: 13),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              "${"observation".tr} :",
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(color: AppColor.text),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppColor.textField,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColor.lightGrey, width: 1),
                              ),
                              child: TextField(
                                controller: observationController,
                                maxLines: null,
                                expands: true,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(color: AppColor.text, fontSize: 14),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                  hintText: "observationTitle".tr,
                                  hintStyle: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(color: AppColor.labelText, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "attachFiles".tr,
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(color: AppColor.text),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickFiles,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColor.textField,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColor.lightGrey, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  file == null
                                      ? "supportedFileTypesPDF,JPG".tr
                                      : file!.name,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(color: AppColor.labelText, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppFillButton3(
                                    onPressed: () {
                                      setState(() {
                                        _selectedStudentId = null;
                                        observationController.clear();
                                        file = null;
                                      });
                                    },
                                    text: "discard",
                                    color: AppColor.textField,
                                    textColor: AppColor.accentBorder),
                                AppFillButton3(
                                    onPressed: _saveObservation,
                                    text: "submit",
                                    color: AppColor.buttonGreen),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (loading || viewModel.loading) const LoaderView(),
        ],
      ),
    );
  }
}
