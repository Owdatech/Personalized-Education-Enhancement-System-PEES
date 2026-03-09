import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Models/observation_model.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppSection.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObservationScreen extends StatefulWidget {
  StudentModel? model;
  ObservationScreen({this.model, super.key});

  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {
  TeacherService viewModel = TeacherService();
  TextEditingController obsdateController = TextEditingController();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  TextEditingController observationController = TextEditingController();
  html.File? file;
  String? _trxnStatus;
  ReportCardModel? model;
  bool isAddObservation = false;
  String? date;
  String? subjectName;
  String? description;
  // List subjectList = [];
  ObservationModel? obsModel;
  String? subjectname;
  DateTime? _obsSelectedDate;
  bool isViewDetails = false;
  List<Curriculum> curriculumList = [];
  List<Curriculum> filteredCurriculumList = [];
  List<String> subjects = [];
  String? selectedCurriculum;
  String? selectedSubject;
  String attendanceStatus = 'Present';
  String? selectedBehaviorInClass;
  List<String> curriculumNames = [];
  String? imageUrl;
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

  _obsSelectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _obsSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      // selectableDayPredicate: (DateTime value) =>
      //     value.isAfter(DateTime.now()) ? false : true,
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
      obsdateController
        ..text = DateFormat('dd-MM-yyyy').format(_obsSelectedDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: obsdateController.text.length,
            affinity: TextAffinity.upstream));
    }
  }

  void _setObservationDateToToday() {
    _obsSelectedDate = DateTime.now();
    obsdateController
      ..text = DateFormat('dd-MM-yyyy').format(_obsSelectedDate!)
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: obsdateController.text.length),
      );
  }

  fetchObservation() async {
    int? code =
        await viewModel.getObservationList(widget.model?.studentId ?? "");
  }

  loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String url = '${Config.curriculumBaseURL}curriculum?teacherId=$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> curriculumJson = data['curriculum'];
        curriculumList =
            curriculumJson.map((json) => Curriculum.fromJson(json)).toList();

        // Filter by grade
        filteredCurriculumList = curriculumList
            .where((item) =>
                item.grade.toLowerCase() == widget.model?.grade?.toLowerCase())
            .toList();

        print("Filtered Curriculum List == $filteredCurriculumList");

        // Extract subjects
        subjects =
            filteredCurriculumList.map((e) => e.subject).toSet().toList();
        print("Filtered Subject List == $subjects");

        if (subjects.isNotEmpty &&
            (selectedSubject == null || !subjects.contains(selectedSubject))) {
          selectedSubject = subjects.first;
        }

        // If a subject is selected, filter curriculum names
        filterCurriculumBySubject();

        setState(() {}); // Update UI
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void filterCurriculumBySubject() {
    if (selectedSubject != null) {
      curriculumNames = filteredCurriculumList
          .where((item) =>
              item.subject.toLowerCase() == selectedSubject?.toLowerCase())
          .map((e) => e.curriculumName)
          .toSet() // Remove duplicates
          .toList();
    } else {
      curriculumNames = filteredCurriculumList
          .map((e) => e.curriculumName)
          .toSet() // Remove duplicates
          .toList();
    }
  }

  void _pickFiles() async {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept =
          'application/pdf,image/*'; // Restrict file types if needed
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          setState(() {
            file = files.first;
          });
        } else {
          print("No file selected");
        }
      }); // Get the
    } catch (e) {
      print("Error picking files: $e");
    }
  }

  addObeservation(html.File? file) async {
    String studId = widget.model?.studentId.toString() ?? "";
    String date = obsdateController.text.trim();
    String observation = observationController.text.trim();
    String subject = selectedSubject?.trim() ?? "";

    // All fields empty — show combined message
    if (date.isEmpty && subject.isEmpty && observation.isEmpty) {
      Utils.snackBar("Please fill in all required fields", context);
      return;
    }

    // Individual field validation
    if (date.isEmpty) {
      Utils.snackBar("Please select a date", context);
      return;
    }

    if (subject.isEmpty || subject == "null") {
      Utils.snackBar("Please select a subject", context);
      return;
    }

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
      observation = "${"selectedDateLabel".tr}: $date\n$observation";
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
      final behaviorLabel = "behaviorInClass".tr;
      final behaviorValue = selectedBehaviorInClass!.tr;
      final behaviorLinePattern = RegExp(
          r'^\s*(Behavior in Class|Behaviour in Class|سلوك الطالب في الصف)\s*:',
          caseSensitive: false);
      if (!behaviorLinePattern.hasMatch(observation)) {
        observation = "$behaviorLabel: $behaviorValue\n$observation";
      }
    }

    // Proceed with API call
    String apiDate = date;
    if (_obsSelectedDate != null) {
      apiDate = DateFormat('yyyy-MM-dd').format(_obsSelectedDate!);
    } else {
      try {
        apiDate = DateFormat('yyyy-MM-dd')
            .format(DateFormat('dd-MM-yyyy').parseStrict(date));
      } catch (_) {
        // Keep the original input if parsing fails.
      }
    }

    int? code = await viewModel.addObservation(
      studId,
      file,
      subject,
      observation,
      apiDate,
    );
    if (context.mounted) {
      if (code == 200) {
        setState(() {
          isAddObservation = false;
        });
        Utils.snackBar("Observation added successfully", context);
        fetchObservation();
        clearMethod();
      } else {
        Utils.snackBar(viewModel.apiError.toString(), context);
        print("API Fail: ${viewModel.apiError}");
      }
    }
  }

  clearMethod() {
    observationController.clear();
    _trxnStatus = null;
    file = null;
    attendanceStatus = 'Present';
    selectedBehaviorInClass = null;
    _setObservationDateToToday();
  }

  String? _observationId(Map<String, dynamic> item) {
    dynamic normalizedId(dynamic value) {
      if (value == null) return null;
      final idText = value.toString().trim();
      if (idText.isEmpty) return null;
      if (idText.toLowerCase() == 'null') return null;
      return idText;
    }

    dynamic searchId(dynamic node) {
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key.toString().toLowerCase().replaceAll('_', '');
          if (key == 'id' ||
              key == '_id' ||
              key == 'observationid' ||
              key.endsWith('id')) {
            final value = normalizedId(entry.value);
            if (value != null) return value;
          }
        }
        for (final value in node.values) {
          final nested = searchId(value);
          if (nested != null) return nested;
        }
      } else if (node is List) {
        for (final value in node) {
          final nested = searchId(value);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return searchId(item)?.toString();
  }

  Future<void> _showDeleteObservationDialog(Map<String, dynamic> item) async {
    final observationId = _observationId(item);
    if (observationId == null) {
      Utils.snackBar(
          "This observation cannot be deleted because the server did not return an observation ID.",
          context);
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Observation"),
        content:
            const Text("Are you sure you want to delete this observation?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final studId = widget.model?.studentId.toString() ?? "";
    final code = await viewModel.deleteObservation(studId, observationId);
    if (!mounted) return;

    if (code == 200 || code == 204) {
      Utils.snackBar("Observation deleted successfully", context);
      fetchObservation();
    } else if (code == 404) {
      Utils.snackBar(
          "Delete endpoint not found or ID missing on server", context);
    } else {
      Utils.snackBar("Failed to delete observation", context);
    }
  }

  Future<void> _showEditObservationDialog(Map<String, dynamic> item) async {
    final observationId = _observationId(item);
    if (observationId == null) {
      Utils.snackBar(
          "This observation cannot be edited because the server did not return an observation ID.",
          context);
      return;
    }

    final subjectController =
        TextEditingController(text: item['subject']?.toString() ?? "");
    final observationTextController =
        TextEditingController(text: item['observation']?.toString() ?? "");

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Observation"),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observationTextController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: "Observation"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    final subject = subjectController.text.trim();
    final observation = observationTextController.text.trim();
    if (subject.isEmpty || observation.isEmpty) {
      Utils.snackBar("Subject and observation are required", context);
      return;
    }

    final studId = widget.model?.studentId.toString() ?? "";
    final code = await viewModel.updateObservation(
      studId,
      observationId,
      subject,
      observation,
    );

    if (!mounted) return;
    if (code == 200 || code == 204) {
      Utils.snackBar("Observation updated successfully", context);
      fetchObservation();
    } else if (code == 404) {
      Utils.snackBar(
          "Update endpoint not found or ID missing on server", context);
    } else {
      Utils.snackBar("Failed to update observation", context);
    }
  }

  @override
  void initState() {
    fetchObservation();
    // fetchSubjectList();
    loadCurriculum();
    _setObservationDateToToday();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.bgLavender,
              body: Stack(
                children: [
                  isMobile ? SizedBox() : const BackButtonWidget(),
                  Padding(
                      padding: EdgeInsets.only(
                          left: isMobile ? 12 : 100,
                          right: isMobile ? 12 : 100,
                          top: 30),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            isMobile
                                ? const BackButtonWidget()
                                : const SizedBox(),
                            SizedBox(height: isMobile ? 5 : 0),
                            Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: AppColor.panelDarkSoft,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                          blurRadius: 15,
                                          offset: Offset(0, 10),
                                          color: AppColor.greyShadow)
                                    ]),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: isMobile ? 8 : 70,
                                      right: isMobile ? 8 : 70),
                                  child: Column(
                                    children: [
                                      studentInformation(),
                                      const SizedBox(height: 30),
                                      AppSection(
                                        title: "observation".tr,
                                        child: isViewDetails == true
                                            ? detailsViewUI()
                                            : Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(
                                                        17, 14, 17, 4),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            isAddObservation =
                                                                true;
                                                            if (obsdateController
                                                                .text.isEmpty) {
                                                              _setObservationDateToToday();
                                                            }
                                                          });
                                                        },
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 10),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppColor
                                                                .panelDarkSoft,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            border: Border.all(
                                                                color: AppColor
                                                                    .buttonGreen,
                                                                width: 1.4),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons.add,
                                                                color: AppColor
                                                                    .buttonGreen,
                                                                size: 18,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                "addNewObservation"
                                                                    .tr,
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .semibold
                                                                    .copyWith(
                                                                        color: AppColor
                                                                            .buttonGreen),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  isAddObservation == true
                                                      ? addObservationUI()
                                                      : SizedBox(),
                                                  SizedBox(
                                                    height:
                                                        isMobile ? 420 : 520,
                                                    child:
                                                        SingleChildScrollView(
                                                      child: obsList(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 50),
                          ],
                        ),
                      )),
                  value.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget detailsViewUI() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColor.panelDarkSoft,
                  borderRadius: BorderRadius.circular(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 7 : 15,
                        right: isMobile ? 7 : 15,
                        top: 15,
                        bottom: 5),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text("${"subjectTitle".tr} $subjectName",
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.text)),
                                const SizedBox(height: 5),
                                AppFillButton3(
                                    onPressed: () {
                                      setState(() {
                                        isViewDetails = false;
                                      });
                                    },
                                    text: "hideDetails",
                                    color: AppColor.buttonGreen),
                              ])
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${"subjectTitle".tr} $subjectName",
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text)),
                              AppFillButton3(
                                  onPressed: () {
                                    setState(() {
                                      isViewDetails = false;
                                    });
                                  },
                                  text: "hideDetails",
                                  color: AppColor.buttonGreen),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: AppColor.panelDark,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              width: 1, color: AppColor.buttonGreen)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          description ?? "",
                          style: NotoSansArabicCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.text),
                        ),
                      ),
                    ),
                  ),
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColor.buttonGreen, width: 1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text("Image failed to load"),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget studentInformation() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  isMobile
                      ? Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.lightGrey),
                          child: ClipRRect(
                            child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    NetworkImage(widget.model?.photourl ?? "")),
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 10),
                  Text(widget.model?.studentName ?? "",
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.text)),
                  const SizedBox(height: 15),
                  Text("${"email".tr} ${widget.model?.email ?? ""}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.text)),
                  const SizedBox(height: 15),
                  Text(widget.model?.classSection ?? "",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.text)),
                  const SizedBox(height: 15),
                  Text("${"grade".tr} : ${widget.model?.grade ?? ""}",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.text)),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            isMobile
                ? SizedBox()
                : Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColor.lightGrey),
                    child: ClipRRect(
                      child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(widget.model?.photourl ?? "")),
                    ),
                  ),
          ],
        ),
      );
    });
  }

  Widget obsSelectSubject() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    if (selectedSubject != null && !subjects.contains(selectedSubject)) {
      selectedSubject = subjects.isNotEmpty ? subjects.first : null;
    }

    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton<String>(
          isDense: true,
          hint: Padding(
            padding: const EdgeInsets.only(left: 15, top: 2),
            child: Text("selectSubject".tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize,
                    color: AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Image.asset(AppImage.arrowDown, width: 16),
          ),
          isExpanded: true,
          value: selectedSubject,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              selectedSubject = value;
            });
          },
          items: subjects.isNotEmpty
              ? subjects.map<DropdownMenuItem<String>>((value) {
                  return DropdownMenuItem(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, left: 10),
                        child: Text(
                          value,
                          style: NotoSansArabicCustomTextStyle.regular.copyWith(
                              color: AppColor.text,
                              fontSize: fontSizeProvider.fontSize),
                        ),
                      ));
                }).toList()
              : [],
        ),
      ),
    );
  }

  String formatDate(String dateString) {
    DateTime parsedDate =
        DateTime.parse(dateString); // Parse the string into DateTime
    return DateFormat('dd-MM-yyyy')
        .format(parsedDate); // Format it as dd-MM-yyyy
  }

  Widget obsList() {
    final sortedList = viewModel.observationsList
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          for (int i = 0; i < sortedList.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  left: isMobile ? 7 : 17,
                  right: isMobile ? 7 : 17,
                  top: 8,
                  bottom: 8),
              child: Container(
                // height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColor.panelDarkSoft,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 15,
                          offset: Offset(0, 10),
                          color: AppColor.blueShadow)
                    ]),
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 8, bottom: 8, right: 20, left: 20),
                  child: isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sortedList[i]['observation'],
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.text)),
                            const SizedBox(height: 7),
                            Text(
                                "${"subject".tr} : ${sortedList[i]['subject']}",
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.text)),
                            const SizedBox(height: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppFillButton3(
                                    onPressed: () {
                                      setState(() {
                                        isViewDetails = true;
                                        date = sortedList[i]['date'];
                                        subjectName = sortedList[i]['subject'];
                                        description =
                                            sortedList[i]['observation'];
                                        imageUrl =
                                            sortedList[i]['attachment_url'];
                                      });
                                    },
                                    text: "viewObservation",
                                    color: AppColor.buttonGreen),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColor.text,
                                        side: const BorderSide(
                                            color: AppColor.accentBorder),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () =>
                                          _showEditObservationDialog(
                                              Map<String, dynamic>.from(
                                                  sortedList[i])),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      label: Text("edit".tr),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColor.brown,
                                        side: const BorderSide(
                                            color: AppColor.brown),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () =>
                                          _showDeleteObservationDialog(
                                              Map<String, dynamic>.from(
                                                  sortedList[i])),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      label: Text("delete".tr),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sortedList[i]['observation'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.text),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 220,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      "${"subject".tr} : ${sortedList[i]['subject']}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.text)),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AppFillButton3(
                                          onPressed: () {
                                            setState(() {
                                              isViewDetails = true;
                                              date = sortedList[i]['date'];
                                              subjectName =
                                                  sortedList[i]['subject'];
                                              description = sortedList[i]
                                                  ['observation'];
                                              imageUrl = sortedList[i]
                                                  ['attachment_url'];
                                            });
                                          },
                                          text: "viewObservation",
                                          color: AppColor.buttonGreen),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColor.text,
                                              side: const BorderSide(
                                                  color:
                                                      AppColor.accentBorder),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                            ),
                                            onPressed: () =>
                                                _showEditObservationDialog(
                                                    Map<String, dynamic>.from(
                                                        sortedList[i])),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18),
                                            label: Text("edit".tr),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColor.brown,
                                              side: const BorderSide(
                                                  color: AppColor.brown),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                            ),
                                            onPressed: () =>
                                                _showDeleteObservationDialog(
                                                    Map<String, dynamic>.from(
                                                        sortedList[i])),
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18),
                                            label: Text("delete".tr),
                                          ),
                                        ],
                                      ),
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
        ],
      );
    });
  }

  Widget addObservationFormUI() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Teacher’s Notes :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.text)),
              const SizedBox(width: 20),
              Container(
                  height: 200,
                  width: 668,
                  decoration: BoxDecoration(
                      color: AppColor.panelDark,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "List of Notes for student",
                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.text),
                    ),
                  ))
            ],
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Feedback :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.text)),
              const SizedBox(width: 75),
              Container(
                  height: 200,
                  width: 668,
                  decoration: BoxDecoration(
                      color: AppColor.panelDarkSoft,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Provided Feedback",
                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.text),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget addObservationUI() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Padding(
        padding: EdgeInsets.only(
            top: 20, left: isMobile ? 7 : 30, right: isMobile ? 7 : 30),
        child: Column(
          children: [
            Container(
              // height: 40,
              width: double.infinity,
              decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: AppColor.greyShadow,
                        offset: Offset(0, 10),
                        blurRadius: 15)
                  ],
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  color: AppColor.lightYellow),
              child: Padding(
                padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Center(
                    child: Text("addObservation".tr,
                        style: PoppinsCustomTextStyle.medium.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.white)),
                  ),
                ),
              ),
            ),
            Container(
              // height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: AppColor.panelDark,
                  boxShadow: [
                    BoxShadow(
                        color: AppColor.greyShadow,
                        offset: Offset(0, 10),
                        blurRadius: 15)
                  ],
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5))),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: 9,
                        left: selectedLanguage == 'en'
                            ? isMobile
                                ? 10
                                : 20
                            : isMobile
                                ? 10
                                : 20,
                        right: selectedLanguage == 'en'
                            ? isMobile
                                ? 10
                                : 20
                            : isMobile
                                ? 10
                                : 20),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 10,
                      alignment: selectedLanguage == 'ar'
                          ? WrapAlignment.end
                          : WrapAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("date".tr,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                    height: 25,
                                    child: AppFillTextField(
                                        textController: obsdateController,
                                        readOnly: true,
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              _obsSelectDate(context);
                                            },
                                            padding:
                                                const EdgeInsets.only(left: 15),
                                            icon: Image.asset(
                                              AppImage.calendar,
                                              width: 45,
                                            )),
                                        hintText: "selectDate".tr,
                                        icon: null)),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "subject".tr,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.text),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: obsSelectSubject()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(
                        left: selectedLanguage == 'en'
                            ? isMobile
                                ? 10
                                : 20
                            : isMobile
                                ? 10
                                : 20,
                        right: selectedLanguage == 'en'
                            ? isMobile
                                ? 10
                                : 20
                            : isMobile
                                ? 10
                                : 20),
                    child: Align(
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
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.text),
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
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text),
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
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (attendanceStatus != 'Absent') ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(
                          left: selectedLanguage == 'en'
                              ? isMobile
                                  ? 10
                                  : 20
                              : isMobile
                                  ? 10
                                  : 20,
                          right: selectedLanguage == 'en'
                              ? isMobile
                                  ? 10
                                  : 20
                              : isMobile
                                  ? 10
                                  : 20),
                      child: Align(
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
                                "${"behaviorInClass".tr} :",
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize:
                                            fontSizeProvider.fontSize,
                                        color: AppColor.text),
                              ),
                              Container(
                                height: 32,
                                width: isMobile ? 260 : 330,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColor.textField,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1.0, color: AppColor.textGrey),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBehaviorInClass,
                                    isExpanded: true,
                                    dropdownColor: AppColor.panelDarkSoft,
                                    style:
                                        NotoSansArabicCustomTextStyle.regular
                                            .copyWith(
                                                fontSize:
                                                    fontSizeProvider.fontSize,
                                                color: AppColor.white),
                                    hint: Text(
                                      "selectBehaviorInClass".tr,
                                      overflow: TextOverflow.ellipsis,
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.textGrey),
                                    ),
                                    icon: Image.asset(AppImage.arrowDown,
                                        width: 16),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedBehaviorInClass = value;
                                      });
                                    },
                                    items: _behaviorOptions
                                        .map((optionKey) =>
                                            DropdownMenuItem<String>(
                                              value: optionKey,
                                              child: Text(
                                                optionKey.tr,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: NotoSansArabicCustomTextStyle
                                                    .regular
                                                    .copyWith(
                                                        fontSize:
                                                            fontSizeProvider
                                                                .fontSize,
                                                        color: AppColor.white),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: isMobile ? 90 : 130,
                                child: Text(
                                  "observationTitle".tr,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text),
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Container(
                                  height: 88,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppColor.extralightGrey),
                                  child: TextField(
                                    controller: observationController,
                                    style: PoppinsCustomTextStyle.regular
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.text),
                                    decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.only(left: 7)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: isMobile ? 90 : 130,
                                child: Text(
                                  "attachFiles".tr,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.text),
                                ),
                              ),
                              const SizedBox(width: 25),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    _pickFiles();
                                  },
                                  child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: AppColor.extralightGrey),
                                      child: Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                              "${file != null ? file?.name : "supportedFileTypesPDF,JPG".tr}"))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: isMobile
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: isMobile
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isAddObservation = false;
                                      clearMethod();
                                    });
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColor.panelDarkSoft,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          width: 1,
                                          color: AppColor.buttonGreen),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "cancel".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                fontSize:
                                                    fontSizeProvider.fontSize,
                                                color: AppColor.buttonGreen),
                                      ),
                                    ),
                                  ),
                                ),
                                isMobile
                                    ? SizedBox(width: 20)
                                    : SizedBox(width: 30),
                                AppFillButton2(
                                    onPressed: () {
                                      addObeservation(
                                          file); // file can be null now
                                    },

                                    // onPressed: () {
                                    //   if (file != null) {
                                    //     addObeservation(file!);
                                    //   } else {
                                    //     Utils.snackBar(
                                    //         "attachFile".tr, context);
                                    //   }
                                    //   // addObeservation(file!);
                                    // },
                                    text: "submit"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
