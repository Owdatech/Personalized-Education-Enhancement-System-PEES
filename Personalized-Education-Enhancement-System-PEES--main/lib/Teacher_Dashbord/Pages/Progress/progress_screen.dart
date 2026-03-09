import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/analyze_report.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProgressScreen extends StatefulWidget {
  final StudentModel? model;

  // Parent dashboard fields
  final String? studentId;
  final String? userName;
  final String? photoUrl;
  final String? teacherName;
  final String? grade;
  final String? className;
  final String? email;

  // Constructor from Teacher Dashboard (full model)
  ProgressScreen.fromModel({required this.model, super.key})
      : studentId = null,
        userName = null,
        photoUrl = null,
        teacherName = null,
        grade = null,
        className = null,
        email = null;

  // Constructor from Parent Dashboard (individual fields)
  ProgressScreen.fromParent({
    required this.studentId,
    required this.userName,
    required this.photoUrl,
    required this.teacherName,
    required this.grade,
    required this.className,
    required this.email,
    super.key,
  }) : model = null;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  TeacherService viewModel = TeacherService();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  DateTime? _selectedFDate;
  DateTime? _selectedTDate;
  ReportCardModel? model;
  GlobalKey keyGrade = GlobalKey();
  GlobalKey keyAttendance = GlobalKey();
  GlobalKey keyPerformance = GlobalKey();
  String? firstDate;
  String? lastDate;
  DateTime? availableStartDate;
  DateTime? availableEndDate;
  String? fromDates;
  String? toDates;
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  int selectedIndex = 0;
  Progress selectedTab = Progress.progress;
  String? fetchSelectSubject;
  List<String> filterSubject = [];
  List<Curriculum> curriculumList = [];
  List<Curriculum> filteredCurricula = [];
  bool isDatafilter = false;
  late TooltipBehavior _tooltipBehavior;
  String get studentId {
    return widget.model?.studentId ?? widget.studentId ?? "";
  }

  fetchReportData() async {
    ReportCardModel? rModel = await viewModel.getReportCardApicall(studentId);
    if (rModel != null) {
      model = rModel;
    }
  }

  fetchGardeData(String startDate, String endDate) async {
    String? studId = widget.model?.studentId ?? "";
    int? code =
        await viewModel.getGradeGraphwithFilter(studentId, startDate, endDate);
    if (code == 200) {
      print("Success grade data");
    } else {
      print("Garade Data Error : ${viewModel.apiError}");
    }
  }

  fetchAllGarde() async {
    String? studId = widget.model?.studentId ?? "";
    int? code = await viewModel.getGradeGraph(studentId);
    if (code == 200) {
      print("Success all grade data");
    } else {
      print("All Garade Data Error : ${viewModel.apiError}");
    }
  }

  Future<Uint8List> capturePng(GlobalKey key) async {
    RenderRepaintBoundary? boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return Uint8List(0);
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  exportWithPdf(String startDate, String endDate) async {
    String? url = await viewModel.exportProgress(
        studentId, 'pdf', startDate, endDate, selectedLanguage ?? "");
    if (url != null) {
      downloadPDFFile(url);
    } else {
      print("Export Url Error PDF ${viewModel.apiError}");
    }
  }

  void downloadPDFFile(String url) async {
    // final anchorElement = html.AnchorElement(href: url)
    //   ..setAttribute("download", "ProgressReport.pdf")
    //   ..click();

    // html.Url.revokeObjectUrl(url);
    html.window.open(url, "ProgressReport.pdf");
  }

  exportWithExcel(String startDate, String endDate) async {
    String? url = await viewModel.exportProgress(
        studentId, 'excel', startDate, endDate, selectedLanguage ?? "en");
    if (url != null) {
      downloadExcelFile(url);
    } else {
      print("Export Url Error Excel ${viewModel.apiError}");
    }
  }

  void downloadExcelFile(String url) async {
    final anchorElement = html.AnchorElement(href: url)
      ..setAttribute("download", "ProgressReport.excel")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      final response = await http
          .get(Uri.parse('${Config.curriculumBaseURL}curriculum?teacherId=$userId'));
      viewModel.setLoading(true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> curriculumJson = data['curriculum'];
        print("Response  : ${response.body}");
        curriculumList =
            curriculumJson.map((item) => Curriculum.fromJson(item)).toList();
        setState(() {
          filteredCurricula = curriculumList
              .where((curriculum) =>
                  curriculum.grade.toLowerCase() ==
                  widget.model?.grade?.toLowerCase())
              .toList();
          print("Curriculum List Length : $filteredCurricula");
          filterSubject = filteredCurricula
              .map((subject) => subject.subject)
              .toSet()
              .toList();
          print("Subject List : $filterSubject");
          if (filterSubject.isNotEmpty) {
            fetchSelectSubject = filterSubject.first;
          } else {
            fetchSelectSubject = null;
          }
        });
        if (fetchSelectSubject != null) {
          fetchImprovementAreas(fetchSelectSubject!);
        }

        viewModel.setLoading(false);
        viewModel.notifyListeners();
      } else {
        viewModel.setLoading(false);
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      viewModel.setLoading(false);
      print("Exception: $e");
    }
  }

  fetchNewData(String fromDate, String toDate) async {
    int? code = await viewModel.fetchProgressData(studentId, fromDate, toDate);
    if (code == 200) {
      print("Success Progess detail");
    } else {
      print("Failed Progress error : ${viewModel.apiError}");
    }
  }

  String? firstDateStr;
  String? lastDateStr;

  DateTime? _parseRecordDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final parsed = DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceFirst(' ', 'T')) ??
        (value.length >= 10 ? DateTime.tryParse(value.substring(0, 10)) : null);

    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Future<void> _initializeDateRangeFromRecords() async {
    final today = DateTime.now();
    final wideStart = "2000-01-01";
    final wideEnd = DateFormat('yyyy-MM-dd').format(today);

    await fetchNewData(wideStart, wideEnd);

    final List<DateTime> recordDates = viewModel.fullDataTableEntries
        .map((entry) => _parseRecordDate(entry.timestamp))
        .whereType<DateTime>()
        .toList();

    if (!mounted) return;

    if (recordDates.isEmpty) {
      setState(() {
        availableStartDate = DateTime(today.year, today.month, today.day);
        availableEndDate = DateTime(today.year, today.month, today.day);
        firstDateStr = DateFormat('yyyy-MM-dd').format(availableStartDate!);
        lastDateStr = DateFormat('yyyy-MM-dd').format(availableEndDate!);
        firstDate = firstDateStr;
        lastDate = lastDateStr;
        fromDateController.text = firstDateStr!;
        toDateController.text = lastDateStr!;
        _selectedFDate = availableStartDate;
        _selectedTDate = availableEndDate;
      });
      return;
    }

    recordDates.sort((a, b) => a.compareTo(b));
    final minDate = recordDates.first;
    final maxDate = recordDates.last;
    final formatter = DateFormat('yyyy-MM-dd');

    setState(() {
      availableStartDate = minDate;
      availableEndDate = maxDate;
      firstDateStr = formatter.format(minDate);
      lastDateStr = formatter.format(maxDate);
      firstDate = firstDateStr;
      lastDate = lastDateStr;
      fromDateController.text = firstDateStr!;
      toDateController.text = lastDateStr!;
      _selectedFDate = minDate;
      _selectedTDate = maxDate;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeDateRangeFromRecords();
    // subjectVisibility = {
    //   for (var sp in viewModel.subjectPercentages) sp.subject: true,
    // };
    // for (int i = 0; i < viewModel.subjectPercentages.length; i++) {
    //   final subject = viewModel.subjectPercentages[i].subject;
    //   subjectColors[subject] = viewModel.colors[i % viewModel.colors.length];
    //   subjectVisibility[subject] = true; // Show all by default
    // }
    for (var sp in viewModel.subjectPercentages) {
      subjectVisibility[sp.subject] = true;
    }
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      format: 'point.x : point.y%',
      canShowMarker: true,
      header: '',
    );
  }

  bool get isFromTeacher => widget.model != null;

  bool isRepaint = false;
  @override
  Widget build(BuildContext context) {
    final visibleSubjects = viewModel.subjectPercentages
        .where((sp) => subjectVisibility[sp.subject] == true)
        .toList();
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.bgLavender,
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
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
                                    child: isFromTeacher
                                        ? Column(
                                            children: [
                                              studentInformation(),
                                              topTabBar(),
                                              selectedTab == Progress.progress
                                                  ? pregress(isMobile)
                                                  : improvement(isMobile),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              studentInformation(),
                                              pregress(isMobile),
                                            ],
                                          ))),
                            const SizedBox(height: 50),
                          ],
                        ),
                      )),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget improvement(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // dropdown
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: subjectDropDown(),
            ),
            // improvement
            areasForImprovement.isEmpty
                ? Center(
                    child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text("noImprovement".tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(color: AppColor.text)),
                  ))
                : Container(
                    width: MediaQuery.of(context).size.width / 1.4,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   "areasforImprovement".tr,
                        //   style: NotoSansArabicCustomTextStyle.medium
                        //       .copyWith(fontSize: 15, color: AppColor.text),
                        // ),
                        const SizedBox(height: 10),
                        ...areasForImprovement
                            .map((area) => Text(
                                  area,
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(color: AppColor.text),
                                ))
                            .toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget subjectDropDown() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor = themeManager.isHighContrast
        ? AppColor.panelDark
        : AppColor.panelDarkSoft;
    Color textColor = AppColor.white;
    Color borderColor = themeManager.isHighContrast
        ? AppColor.accentBorder
        : AppColor.lightGrey;
    if (fetchSelectSubject != null &&
        !filterSubject.contains(fetchSelectSubject)) {
      fetchSelectSubject =
          filterSubject.isNotEmpty ? filterSubject.first : null;
    }

    return SizedBox(
      height: 50,
      width: 250,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: "Select a subject",
          hintStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: bgColor,
          border:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2)),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2)),
        ),
        value: fetchSelectSubject, // Must be in subjects list
        items: filterSubject.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject, style: TextStyle(color: textColor)),
          );
        }).toList(),
        onChanged: (String? newSubject) {
          if (newSubject != null) {
            setState(() {
              fetchSelectSubject = newSubject;
              print("select subject = $fetchSelectSubject");
            });
            fetchImprovementAreas(newSubject);
          }
        },
        validator: (value) => value == null ? "Please select a subject" : null,
      ),
    );
  }

  Widget pregress(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(children: [
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5))),
        child: isMobile
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    filters(),
                    const SizedBox(height: 20),
                    gradeChart(),
                    const SizedBox(height: 20),
                    subjectPerformanceChart(),
                    const SizedBox(height: 20),
                    studentMarksTable(),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // gradeChart(),
                  // const SizedBox(width: 30),
                  Column(
                    children: [
                      const SizedBox(height: 30),
                      filters(),
                      const SizedBox(height: 30),
                      gradeChart(),
                      const SizedBox(height: 30),
                      subjectPerformanceChart(),
                      const SizedBox(height: 25),
                      studentMarksTable(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ],
              ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isFromTeacher
              ? AppFillButton3(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalyzeReportScreen(
                                  studentId: widget.model?.studentId ?? "",
                                )));
                  },
                  text: "analyzeReport",
                  color: AppColor.buttonGreen)
              : SizedBox.shrink(),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PopupMenuButton<String>(
                onSelected: (value) {
                  print('Selected Export: $value');
                },
                offset: const Offset(0, 50),
                itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                          value: "Option 1",
                          onTap: () {
                            isDatafilter == true
                                ? exportWithPdf(fromDateController.text,
                                    toDateController.text)
                                : exportWithPdf(firstDateStr.toString(),
                                    lastDateStr.toString());
                          },
                          child: Text(
                            "exportWithPdf".tr,
                            style: PoppinsCustomTextStyle.medium.copyWith(
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen,
                                fontSize: 15),
                          )),
                      PopupMenuItem(
                          value: "Option 2",
                          onTap: () {
                            isDatafilter == true
                                ? exportWithExcel(fromDateController.text,
                                    toDateController.text)
                                : exportWithExcel(firstDateStr.toString(),
                                    lastDateStr.toString());
                          },
                          child: Text(
                            "exportWithExcel".tr,
                            style: PoppinsCustomTextStyle.medium.copyWith(
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen,
                                fontSize: 15),
                          )),
                    ],
                child: Container(
                    decoration: BoxDecoration(
                        color: AppColor.buttonGreen,
                        borderRadius: BorderRadius.circular(7)),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        child: Text("export".tr,
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: 16, color: AppColor.white))))),
          ),
        ],
      ),
      const SizedBox(height: 20),
    ]);
  }

  Widget studentInformation() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    // Determine data source
    final isFromTeacher = widget.model != null;

    final photoUrl =
        isFromTeacher ? widget.model!.photourl : widget.photoUrl ?? "";
    final studentName =
        isFromTeacher ? widget.model!.studentName : widget.userName ?? "";
    final email = isFromTeacher ? widget.model!.email : widget.email ?? "";
    final grade = isFromTeacher ? widget.model!.grade : widget.grade ?? "";
    final classSection =
        isFromTeacher ? widget.model!.classSection : widget.className ?? "";
    final assignedteacher = isFromTeacher ? "" : widget.teacherName ?? "";
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

                  // Profile Image (mobile first)
                  if (isMobile)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColor.lightGrey),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(photoUrl.toString())),
                      ),
                    ),

                  const SizedBox(height: 15),

                  // Student Name
                  Text(studentName.toString(),
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.text)),

                  const SizedBox(height: 15),

                  // Email
                  Text("${"email".tr} $email",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.text)),

                  const SizedBox(height: 15),

                  // Class Section
                  Text("${"className".tr} : $classSection",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.text)),

                  const SizedBox(height: 15),

                  // Grade
                  Text("${"grade".tr} : $grade",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.text)),
                  // const SizedBox(height: 15),
                  // isFromTeacher? SizedBox.shrink():  Text("${"assignedteacher".tr} : $assignedteacher",
                  //     style: NotoSansArabicCustomTextStyle.medium
                  //         .copyWith(fontSize: 13, color: AppColor.text)),
                  const SizedBox(height: 15),
                  const SizedBox(height: 5),
                ],
              ),
            ),

            // Profile Image (desktop)
            if (!isMobile)
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColor.lightGrey),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(photoUrl.toString())),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget attendanceGraph() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // height: 200,
      decoration: BoxDecoration(
          color: AppColor.panelDark,
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ],
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          Container(
            // height: 20,
            width: 500,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  "attendance".tr,
                  style: PoppinsCustomTextStyle.medium.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.white),
                ),
              ),
            ),
          ),
          Container(
            width: 500,
            decoration: const BoxDecoration(
                color: AppColor.panelDarkSoft,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: SizedBox(
              height: 175,
              width: 470,
              child: SfCircularChart(
                legend: const Legend(isVisible: true),
                series: <PieSeries<AttendanceModel, String>>[
                  PieSeries<AttendanceModel, String>(
                    dataSource: viewModel.attendanceChartData,
                    radius: "60",
                    explode: false,
                    xValueMapper: (AttendanceModel data, _) => data.title.tr,
                    yValueMapper: (AttendanceModel data, _) => data.attendence,
                    pointColorMapper: (AttendanceModel data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        textStyle: PoppinsCustomTextStyle.regular
                            .copyWith(fontSize: 12, color: AppColor.text)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
    return formattedDate;
  }

  Map<String, bool> subjectVisibility = {};
  Map<String, Color> subjectColors = {};

  Set<String> selectedSubjects = {}; // replace selectedSubject with this

  Widget gradeChart() {
    final uniqueSubjects =
        viewModel.subjectNewData.map((sp) => sp.subject).toSet().toList();

    // Assign colors once
    if (subjectColors.isEmpty) {
      for (int i = 0; i < uniqueSubjects.length; i++) {
        subjectColors[uniqueSubjects[i]] =
            viewModel.colors[i % viewModel.colors.length];
      }
      selectedSubjects = uniqueSubjects.toSet();
    }

    // Group subject -> unique date records (keep latest per date)
    final Map<String, Map<DateTime, LineGraphModel>> groupedDataByDate = {};
    for (var entry in viewModel.subjectNewData) {
      if (selectedSubjects.contains(entry.subject)) {
        final DateTime normalizedDate = DateTime(
          entry.dateTime.year,
          entry.dateTime.month,
          entry.dateTime.day,
        );
        final model = LineGraphModel(
          subject: entry.subject,
          percentage: entry.percentage,
          date: DateFormat('yyyy-MM-dd').format(normalizedDate),
        );
        groupedDataByDate.putIfAbsent(model.subject, () => {});
        if (!groupedDataByDate[model.subject]!.containsKey(normalizedDate) ||
            groupedDataByDate[model.subject]![normalizedDate]!
                .dateTime
                .isBefore(entry.dateTime)) {
          groupedDataByDate[model.subject]![normalizedDate] = model;
        }
      }
    }

    // Only include actual dates with data and sort them
    final Set<DateTime> actualDatesWithData =
        groupedDataByDate.values.expand((dateMap) => dateMap.keys).toSet();
    final List<DateTime> sortedDates = actualDatesWithData.toList()
      ..sort((a, b) => a.compareTo(b));

    // Chart series for each subject
    final List<CartesianSeries<LineGraphModel?, String>> chartSeries = [];

    // Create chart data for each subject
    groupedDataByDate.forEach((subject, dateMap) {
      final Map<DateTime, LineGraphModel?> mappedData = {
        for (var date in sortedDates) date: null,
      };

      for (var entry in dateMap.entries) {
        mappedData[entry.key] = entry.value;
      }

      final List<LineGraphModel?> finalData = sortedDates.map((date) {
        return mappedData[date]; // Could be null
      }).toList();

      if (selectedSubjects.contains(subject) &&
          finalData.whereType<LineGraphModel>().isNotEmpty) {
        chartSeries.add(
          LineSeries<LineGraphModel?, String>(
            name: subject,
            dataSource: finalData,
            xValueMapper: (data, index) =>
                DateFormat('MMM d').format(sortedDates[index]),
            yValueMapper: (data, _) => data?.percentage,
            color: subjectColors[subject],
            markerSettings: const MarkerSettings(isVisible: true),
            emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
            enableTooltip: true,
            // dataLabelSettings: DataLabelSettings(
            //   isVisible: true,
            //   builder: (data, _, __, ___, ____) {
            //     if (data is LineGraphModel && data.percentage == 0) {
            //       return const SizedBox.shrink();
            //     }
            //     return Text(
            //       '${data?.percentage.toStringAsFixed(0)}%',
            //       style: const TextStyle(fontSize: 12),
            //     );
            //   },
            // ),
          ),
        );
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColor.panelDark,
        boxShadow: const [
          BoxShadow(
            color: AppColor.greyShadow,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          // Title
          Container(
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "Progress",
                  style: PoppinsCustomTextStyle.medium.copyWith(
                    fontSize: Provider.of<FontSizeProvider>(context).fontSize,
                    color: AppColor.white,
                  ),
                ),
              ),
            ),
          ),

          // Chart
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.4,
            height: 370,
            child: SfCartesianChart(
              tooltipBehavior: TooltipBehavior(enable: true),
              onTooltipRender: (tooltipArgs) => {
                if (tooltipArgs.locationY != null)
                  {tooltipArgs.text = '${tooltipArgs.text}%'}
              },
              primaryXAxis: CategoryAxis(
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
                interval: 1,
                labelStyle: const TextStyle(color: AppColor.white),
              ),
              primaryYAxis: const NumericAxis(
                minimum: 0,
                maximum: 100,
                interval: 20,
                labelStyle: TextStyle(color: AppColor.white),
              ),
              series: chartSeries,
            ),
          ),

          // Subject Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              children: uniqueSubjects.map((subject) {
                final isSelected = selectedSubjects.contains(subject);
                final color = subjectColors[subject];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSubjects.add(subject);
                          } else {
                            selectedSubjects.remove(subject);
                          }
                        });
                      },
                      activeColor: color,
                    ),
                    Container(
                      width: 15,
                      height: 15,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(subject,
                        style: const TextStyle(color: AppColor.white)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

// Helper to order months
  int _monthOrder(String month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months.indexOf(month);
  }

  Map<String, bool> subjectVisibilitySubject = {};
  Map<String, Color> subjectColorsSubject = {};

  Widget subjectPerformanceChart() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    // Initialize all subjects as visible if not already present
    if (subjectVisibilitySubject.isEmpty) {
      for (var sp in viewModel.subjectPercentages) {
        subjectVisibilitySubject[sp.subject] = true;
      }
    }

    // Filter visible subjects
    final visibleSubjects = viewModel.subjectPercentages
        .where((sp) => subjectVisibilitySubject[sp.subject] ?? true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.panelDark,
        boxShadow: const [
          BoxShadow(
            color: AppColor.greyShadow,
            blurRadius: 15,
            offset: Offset(0, 10),
          )
        ],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  "subjectPerformance".tr,
                  style: PoppinsCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize,
                    color: AppColor.white,
                  ),
                ),
              ),
            ),
          ),

          // Chart
          Container(
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: const BoxDecoration(
              color: AppColor.panelDarkSoft,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 400,
                  child: SfCartesianChart(
                    primaryXAxis: const CategoryAxis(
                      labelStyle: TextStyle(color: AppColor.white),
                    ),
                    primaryYAxis: const NumericAxis(
                      minimum: 0,
                      maximum: 100,
                      interval: 20,
                      labelStyle: TextStyle(color: AppColor.white),
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<SubjectPercentage, String>(
                        dataSource: visibleSubjects,
                        xValueMapper: (SubjectPercentage data, _) =>
                            data.subject,
                        yValueMapper: (SubjectPercentage data, _) =>
                            data.percentage,
                        pointColorMapper: (SubjectPercentage data, int index) {
                          final originalIndex = viewModel.subjectPercentages
                              .indexWhere((sp) => sp.subject == data.subject);
                          return viewModel
                              .colors[originalIndex % viewModel.colors.length];
                        },
                        width: visibleSubjects.length == 1 ? 0.3 : 0.8,
                        spacing: visibleSubjects.length == 1 ? 0.5 : 0.2,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle:
                              TextStyle(fontSize: 10, color: AppColor.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox List
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      viewModel.subjectPercentages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sp = entry.value;
                    final isVisible =
                        subjectVisibilitySubject[sp.subject] ?? true;
                    final baseColor =
                        viewModel.colors[index % viewModel.colors.length];
                    final displayColor = isVisible ? baseColor : Colors.grey;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isVisible,
                          onChanged: (value) {
                            setState(() {
                              subjectVisibilitySubject[sp.subject] =
                                  value ?? true;
                            });
                          },
                          activeColor: displayColor,
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: displayColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          sp.subject,
                          style: const TextStyle(color: AppColor.white),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isShowall = false;
  Widget studentMarksTable() {
    List<DataRow> rows = [];
    final List<Map<String, String>> items = [];
    viewModel.fullDataTableEntries.map((entry) {
      final dateString = entry.timestamp.toString();
      final shortDate =
          dateString.length >= 10 ? dateString.substring(0, 10) : dateString;
      items.add({
        "subject": entry.subject,
        "marks": entry.marks.toString(),
        "totalMarks": entry.totalMarks.toString(),
        "date": shortDate,
      });
      return rows.add(DataRow(cells: [
        DataCell(
            Text(entry.subject, style: const TextStyle(color: AppColor.text))),
        DataCell(Text(entry.marks.toString(),
            style: const TextStyle(color: AppColor.text))),
        DataCell(Text(entry.totalMarks.toString(),
            style: const TextStyle(color: AppColor.text))),
        DataCell(Text(shortDate, style: const TextStyle(color: AppColor.text))),
      ]));
    }).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 1200;
      final visibleItems = isShowall ? items : items.take(5).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.fullDataTableEntries.isNotEmpty && isNarrow)
            Column(
              children: visibleItems
                  .map((item) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.panelDarkSoft,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(width: 0.8, color: AppColor.lightGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${"subject".tr}: ${item["subject"]}",
                                style: const TextStyle(color: AppColor.text)),
                            const SizedBox(height: 4),
                            Text(
                                "${"marks".tr}: ${item["marks"]} / ${item["totalMarks"]}",
                                style: const TextStyle(color: AppColor.text)),
                            const SizedBox(height: 4),
                            Text("${"dateTitle".tr}: ${item["date"]}",
                                style: const TextStyle(color: AppColor.text)),
                          ],
                        ),
                      ))
                  .toList(),
            )
          else if (viewModel.fullDataTableEntries.isNotEmpty)
            SizedBox(
              width: MediaQuery.of(context).size.width / 1.4,
              child: DataTable(
                headingRowColor: WidgetStateColor.resolveWith(
                    (states) => AppColor.buttonGreen),
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8, color: AppColor.text),
                ),
                columnSpacing: 16,
                columns: [
                  DataColumn(
                      label: Text("subject".tr,
                          style: NotoSansArabicCustomTextStyle.bold
                              .copyWith(fontSize: 15, color: AppColor.white))),
                  DataColumn(
                      label: Text("marks".tr,
                          style: NotoSansArabicCustomTextStyle.bold
                              .copyWith(fontSize: 15, color: AppColor.white))),
                  DataColumn(
                      label: Text("totalMarks".tr,
                          style: NotoSansArabicCustomTextStyle.bold
                              .copyWith(fontSize: 15, color: AppColor.white))),
                  DataColumn(
                      label: Text("dateTitle".tr,
                          style: NotoSansArabicCustomTextStyle.bold
                              .copyWith(fontSize: 15, color: AppColor.white))),
                ],
                rows: isShowall ? rows : rows.take(5).toList(),
              ),
            ),
          if (viewModel.fullDataTableEntries.length > 5)
            const SizedBox(height: 10),
          if (viewModel.fullDataTableEntries.length > 5)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                  onPressed: () {
                    setState(() {
                      isShowall = !isShowall;
                    });
                  },
                  child: Text(isShowall ? "showLess".tr : "showMore".tr,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: 15, color: AppColor.buttonGreen))),
            ),
          const SizedBox(height: 30),
        ],
      );
    });
  }

  filters() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return Container(
      // height: 175,
      width: MediaQuery.of(context).size.width / 1.4,
      decoration: BoxDecoration(
          color: AppColor.panelDark,
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ],
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          Container(
            // height: 20,
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  "filters".tr,
                  style: PoppinsCustomTextStyle.medium.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.white),
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 1.4,
            decoration: const BoxDecoration(
                color: AppColor.panelDarkSoft,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("fromDate".tr,
                        style: PoppinsCustomTextStyle.medium.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.text)),
                    const SizedBox(height: 5),
                    SizedBox(
                        height: 25,
                        width: 250,
                        child: AppFillTextField(
                            textController: fromDateController,
                            readOnly: true,
                            suffixIcon: IconButton(
                                onPressed: () {
                                  selectFromDate(context);
                                },
                                padding: const EdgeInsets.only(left: 15),
                                icon: Image.asset(
                                  AppImage.calendar,
                                  width: 45,
                                )),
                            hintText: "$firstDate",
                            icon: null)),
                    const SizedBox(height: 15),
                    Text("toDate".tr,
                        style: PoppinsCustomTextStyle.medium.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.text)),
                    SizedBox(
                        height: 25,
                        width: 250,
                        child: AppFillTextField(
                            textController: toDateController,
                            readOnly: true,
                            suffixIcon: IconButton(
                                onPressed: () {
                                  selectToDate(context);
                                },
                                padding: const EdgeInsets.only(left: 15),
                                icon: Image.asset(
                                  AppImage.calendar,
                                  width: 45,
                                )),
                            hintText: "$lastDate",
                            icon: null)),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  selectFromDate(BuildContext context) async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final minDate = availableStartDate ?? DateTime(2000);
    final maxDate = availableEndDate ?? DateTime.now();
    final fallbackInitial = minDate.isAfter(maxDate) ? maxDate : minDate;
    final initialDate = _selectedFDate ?? fallbackInitial;
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      // selectableDayPredicate: (DateTime value) =>
      //     value.isAfter(DateTime.now()) ? false : true,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColor.buttonGreen,
                onPrimary: Colors.white,
                surface: AppColor.lightYellow,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColor.white,
                      backgroundColor: AppColor.buttonGreen,
                      textStyle: TextStyle(
                          fontSize: 16,
                          color: themeManager.isHighContrast
                              ? AppColor.black
                              : AppColor.labelText)))),
          child: child!,
        );
      },
    );

    if (newSelectedDate != null) {
      setState(() {
        _selectedFDate = newSelectedDate;
      });
      fromDateController
        ..text = DateFormat('yyyy-MM-dd').format(_selectedFDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: fromDateController.text.length,
            affinity: TextAffinity.upstream));
    }
  }

  selectToDate(BuildContext context) async {
    final minDate = _selectedFDate ?? availableStartDate ?? DateTime(2000);
    final maxDate = availableEndDate ?? DateTime.now();
    final fallbackInitial = _selectedTDate ?? maxDate;
    final initialDate = fallbackInitial.isBefore(minDate)
        ? minDate
        : (fallbackInitial.isAfter(maxDate) ? maxDate : fallbackInitial);
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      // selectableDayPredicate: (DateTime value) =>
      //     value.isAfter(DateTime.now()) ? false : true,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColor.buttonGreen,
                onPrimary: Colors.white,
                surface: AppColor.lightYellow,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColor.white,
                      backgroundColor: AppColor.buttonGreen,
                      textStyle: const TextStyle(fontSize: 16)))),
          child: child!,
        );
      },
    );

    if (newSelectedDate != null) {
      setState(() {
        _selectedTDate = newSelectedDate;
        isDatafilter = true;
      });
      toDateController
        ..text = DateFormat('yyyy-MM-dd').format(_selectedTDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: toDateController.text.length,
            affinity: TextAffinity.upstream));
      fetchNewData(fromDateController.text, toDateController.text);
    }
  }

  Widget topTabBar() {
    return Center(
        child: Row(
      children: [
        tabTitle("reports", Progress.progress, 0),
        tabTitle("improvement", Progress.improvment, 1),
      ],
    ));
  }

  tabTitle(text, Progress type, int selectedItem) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    bool isSelected = type == selectedTab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            changeTabAction(type);
            selectedIndex = selectedItem;
          });
        },
        child: Container(
          width: 460,
          // height: 40,
          decoration: BoxDecoration(
              color: isSelected == true
                  ? AppColor.buttonGreen
                  : AppColor.lightYellow,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(type == Progress.progress
                      ? selectedLanguage == "en"
                          ? 5
                          : 0
                      : selectedLanguage == "en"
                          ? 0
                          : 5),
                  topRight: Radius.circular(type == Progress.progress
                      ? selectedLanguage == "en"
                          ? 0
                          : 5
                      : selectedLanguage == "en"
                          ? 5
                          : 0))),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text("$text".tr,
                  style: PoppinsCustomTextStyle.bold.copyWith(
                      fontSize: fontSizeProvider.fontSize + 1,
                      color: AppColor.white)),
            ),
          ),
        ),
      ),
    );
  }

  List<String> areasForImprovement = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchImprovementAreas(String subjectName) async {
    String apiUrl =
        "${Config.baseURL}student/area_need_improvement?studentId=${widget.model?.studentId}&subjectName=$subjectName&lang=$selectedLanguage";
    viewModel.setLoading(true);
    print("Imrovement URL : $apiUrl");
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      setState(() {
        areasForImprovement.clear(); // Clear previous data before update
      });

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        final Map<String, dynamic> data = json.decode(responseBody);
        print("API Response: ${data['area_for_improvement']}");
        setState(() {
          areasForImprovement = List<String>.from(data['area_for_improvement']);
          viewModel.setLoading(false);
          // fetchSelectSubject = null;
        });
        viewModel.setLoading(false);
      } else {
        print("${response.statusCode} : ${response.body}");
        isLoading = false;
        viewModel.setLoading(false);
      }
    } catch (e) {
      setState(() {
        areasForImprovement.clear();
        errorMessage = "Error: ${e.toString()}";
        viewModel.setLoading(false);
      });
      print("Error: $e");
    }
  }

  changeTabAction(Progress type) async {
    selectedTab = type;
    if (selectedTab == Progress.progress) {
    } else {
      // fetchImprovemnetList();
      loadCurriculum();
    }
  }
}

enum Progress { progress, improvment }

class SubjectPercentage {
  final String subject;
  final double percentage;

  SubjectPercentage({required this.subject, required this.percentage});
}
