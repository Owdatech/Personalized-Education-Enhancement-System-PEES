// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/HeadMaster_Dashboard/Model/student_profile.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/analyze_report.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/update_studentDetail.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Pages/Progress/progress_screen.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/show_history.dart';
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

class StudentDetailsScreen extends StatefulWidget {
  String? studentId;
  String? userRole;
  StudentDetailsScreen({this.studentId, this.userRole, super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  HeadMasterServices masterViewModel = HeadMasterServices();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  DateTime? _selectedFDate;
  DateTime? _selectedTDate;
  String? firstDate;
  String? lastDate;
  String? fromDate;
  List<Curriculum> curriculumList = [];
  List<String> curriculumNames = [];
  List<String> subjects = [];
  ProfileModel? model;
  StudentModel? studModel;
  StudentProfileModel? studentProfileModel;
  ReportCardModel? reportModel;
  int? totalMarks;
  String? grade;
  int? obtainedMarks;
  bool isEditAcademic = false;
  bool isExamScript = false;
  bool isAddObservation = false;
  String? activity;
  String? selectedFile;
  late List<SujbectPerfomanceModel> data;
  html.File? file;
  String? date;
  String? subjectName;
  String? description;
  bool isViewDetails = false;
  String? fetchSelectSubject;
  List<String> filterSubject = [];
  List<Curriculum> filteredCurricula = [];
  bool isDatafilter = false;
  List<String> areasForImprovement = [];
  bool isLoading = true;
  String errorMessage = '';

  fetchObservation() async {
    int? code =
        await masterViewModel.getObservationList(widget.studentId ?? "");
  }

  fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    ProfileModel? profileModel =
        await masterViewModel.getProfileApicall(userId ?? "");
    if (profileModel != null) {
      model = profileModel;
    }
  }

  fetchAcademicData() async {
    ReportCardModel? rModel =
        await masterViewModel.getReportCardApicall(widget.studentId ?? "");
    if (rModel != null) {
      reportModel = rModel;
      setState(() {});
    }
  }

  Future<void> loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      final response = await http
          .get(Uri.parse('${Config.baseURL}curriculum?teacherId=$userId'));
      masterViewModel.setLoading(true);
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
                  studentProfileModel?.grade?.toLowerCase())
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

        masterViewModel.setLoading(false);
        masterViewModel.notifyListeners();
      } else {
        masterViewModel.setLoading(false);
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      masterViewModel.setLoading(false);
      print("Exception: $e");
    }
  }

  cleaMethod() {
    file = null;
  }

  updateStudentAction() {
    Route route = MaterialPageRoute(
        builder: (context) => UpdateStudentDetails(widget.studentId));
    Navigator.push(context, route);
  }

  FutureOr onGoBack(dynamic isRefesh) {
    if (isRefesh) {
      refreshStudentList();
    }
  }

  refreshStudentList() {
    fetchDetails();
  }

  fetchDetails() async {
    List<StudentModel>? models =
        await masterViewModel.fetchStudentListHeadmaster();
    if (models != null) {
      setState(() {
        studModel = models.first;
      });
    }
  }

  fetchGardeDataWithFilter(String startDate, String endDate) async {
    String? studId = widget.studentId ?? "";
    int? code = await masterViewModel.getGradeGraphWithFilter(
        studId, startDate, endDate);
    if (code == 200) {
      print("Success grade data");
    } else {
      print("Garade Data Error : ${masterViewModel.apiError}");
    }
  }

  fetchAllGarde() async {
    String? studId = widget.studentId ?? "";
    int? code = await masterViewModel.getGradeGraph(studId);
    if (code == 200) {
      print("Success all grade data");
    } else {
      print("All Garade Data Error : ${masterViewModel.apiError}");
    }
  }

  fetchTeachingPlan() async {
    int? code =
        await masterViewModel.fetchTeachingPlans(widget.studentId ?? "");
    if (code == 200) {
      print("Teaching Plan Successfully fetch");
    } else {
      print("Teaching plan Error : ${masterViewModel.apiError}");
    }
  }

  setStudentDetails() async {
    StudentProfileModel? model = await masterViewModel
        .fetchStudentProfileDetails(widget.studentId ?? "");
    if (model != null) {
      studentProfileModel = model;
    }
  }

  exportWithPdf(String startDate, String endDate) async {
    String? url = await masterViewModel.exportProgress(widget.studentId ?? "",
        'pdf', startDate, endDate, selectedLanguage ?? "en");
    if (url != null) {
      downloadPDFFile(url);
    } else {
      print("Export Url Error PDF ${masterViewModel.apiError}");
    }
  }

  void downloadPDFFile(String url) async {
    final anchorElement = html.AnchorElement(href: url)
      ..setAttribute("download", "ProgressReport.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  exportWithExcel(String startDate, String endDate) async {
    String? url = await masterViewModel.exportProgress(widget.studentId ?? "",
        'excel', startDate, endDate, selectedLanguage ?? "");
    if (url != null) {
      downloadExcelFile(url);
    } else {
      print("Export Url Error Excel ${masterViewModel.apiError}");
    }
  }

  void downloadExcelFile(String url) async {
    final anchorElement = html.AnchorElement(href: url)
      ..setAttribute("download", "ProgressReport.excel")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  void initState() {
    setStudentDetails();
    fetchProfileData();
    fetchTeachingPlan();
    fetchObservation();
    fetchAcademicData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => masterViewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
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
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: themeManager.isHighContrast
                                      ? AppColor.labelText
                                      : AppColor.white,
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
                                    right: isMobile ? 8 : 70,
                                    bottom: 50),
                                child: Column(
                                  children: [
                                    studentInformation(),
                                    const SizedBox(height: 20),
                                    tabBar(isMobile),
                                    if (masterViewModel.selectedType ==
                                        StudentsFor.academic)
                                      academicTab(isMobile)
                                    else if (masterViewModel.selectedType ==
                                        StudentsFor.teachingPlan)
                                      teachingPlans(isMobile)
                                    else if (masterViewModel.selectedType ==
                                        StudentsFor.observation)
                                      observationTab(isMobile)
                                    else
                                      progressTab(isMobile),
                                    const SizedBox(height: 20),
                                    masterViewModel.selectedType ==
                                            StudentsFor.teachingPlan
                                        ? const SizedBox()
                                        : isEditAcademic == true
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  discardButton(
                                                    () {
                                                      setState(() {
                                                        isEditAcademic = false;
                                                        fetchAcademicData();
                                                      });
                                                    },
                                                  ),
                                                  AppFillButton2(
                                                      onPressed: () {
                                                        // updateReportCard();
                                                      },
                                                      text: "save"),
                                                ],
                                              )
                                            : isExamScript == true
                                                ? const SizedBox()
                                                : masterViewModel
                                                            .selectedType ==
                                                        StudentsFor.observation
                                                    ? const SizedBox()
                                                    : masterViewModel
                                                                .selectedType ==
                                                            StudentsFor.academic
                                                        ? Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              AppFillButton2(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                ShowHistoryScreen(studId: widget.studentId)));
                                                                  },
                                                                  text:
                                                                      "viewExamScripts"),
                                                              // AppFillButton2(
                                                              //     onPressed: () {
                                                              //       Navigator.push(
                                                              //           context,
                                                              //           MaterialPageRoute(
                                                              //               builder: (context) =>
                                                              //                   AnalyzeReportScreen(studentId: widget.studentId)));
                                                              //     },
                                                              //     text:
                                                              //         "viewAnalyzeReport"),
                                                            ],
                                                          )
                                                        : const SizedBox(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  value.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget academicTab(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          color: AppColor.extralightGrey,
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5))),
      child: Padding(
        padding: EdgeInsets.only(
            left: selectedLanguage == 'en'
                ? isMobile
                    ? 10
                    : 50
                : 0,
            right: selectedLanguage == 'en'
                ? isMobile
                    ? 10
                    : 0
                : isMobile
                    ? 10
                    : 100),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // if (isExamScript == true) examScriptFormView() else
            reportViewUI(),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  bool showAll = false;
  Widget reportViewUI() {
    List<DataRow> rows = [];
    reportModel?.subjects.forEach((subjectName, subject) {
      subject.history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      for (var history in subject.history) {
        // String formattedTimestamp =
        //     "${history.timestamp.substring(0, 10)} ${history.timestamp.substring(10)}";
        // DateTime dateTime = DateTime.parse(formattedTimestamp);
        // String formattedDate =
        //     DateFormat("dd-MM-yyyy hh:mm a").format(dateTime);
        rows.add(DataRow(cells: [
          DataCell(
              Text(subjectName, style: const TextStyle(color: AppColor.black))),
          DataCell(Text(history.curriculumName,
              style: const TextStyle(color: AppColor.black))),
          DataCell(Center(
              child: Text(history.marks.toString(),
                  style: const TextStyle(color: AppColor.black)))),
          DataCell(Center(
              child: Text(history.totalMark?.toString() ?? "",
                  style: const TextStyle(color: AppColor.black)))),
          DataCell(Center(
              child: Text(history.grade,
                  style: const TextStyle(color: AppColor.black)))),
          DataCell(Text(_formatTableDate(history.timestamp),
              style: const TextStyle(color: AppColor.black))),
        ]));
      }
    });
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DataTable(
              headingRowColor: WidgetStateColor.resolveWith(
                  (states) => AppColor.buttonGreen), // Header row color
              decoration: BoxDecoration(
                border: Border.all(width: 0.8, color: AppColor.black),
              ),
              columns: [
                DataColumn(
                    label: Text("subject".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
                DataColumn(
                    label: Text("curriculum".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
                DataColumn(
                    label: Text("obtainedMarks".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
                DataColumn(
                    label: Text("totalMarks".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
                DataColumn(
                    label: Text("gradee".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
                DataColumn(
                    label: Text("dateTitle".tr,
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 15, color: AppColor.white))),
              ],
              rows: showAll ? rows : rows.take(5).toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAll = !showAll;
                    });
                  },
                  child: Text(showAll ? "showLess".tr : "showMore".tr,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: 15, color: AppColor.buttonGreen))),
            ),
          ],
        ),
      ),
    );
  }

  Widget tabBar(bool isMobile) {
    return Container(
      // height: 40,
      decoration: const BoxDecoration(
          color: AppColor.lightYellow,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5), topRight: Radius.circular(5))),
      child: topTabBar(isMobile),
    );
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
                                backgroundImage: NetworkImage(
                                    studentProfileModel?.photoUrl ?? "")),
                          ),
                        )
                      : const SizedBox(),
                  isMobile ? const SizedBox(height: 5) : const SizedBox(),
                  isMobile
                      ? AppFillButton3(
                          onPressed: () {
                            updateStudentAction();
                          },
                          text: "editDetails",
                          color: AppColor.buttonGreen)
                      : const SizedBox(),
                  const SizedBox(height: 10),
                  Text(studentProfileModel?.studentName ?? "",
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"email".tr} ${studentProfileModel?.email ?? ""}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text(studentProfileModel?.classSection ?? "",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"grade".tr} : ${studentProfileModel?.grade ?? ""}",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            isMobile
                ? const SizedBox()
                : Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColor.lightGrey),
                        child: ClipRRect(
                          child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                  studentProfileModel?.photoUrl ?? "")),
                        ),
                      ),
                      const SizedBox(height: 5),
                      AppFillButton3(
                          onPressed: () {
                            updateStudentAction();
                          },
                          text: "editDetails",
                          color: AppColor.buttonGreen),
                    ],
                  ),
          ],
        ),
      );
    });
  }

  reportCardDetails() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // height: 175,
      decoration: BoxDecoration(
          color: AppColor.white,
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
            width: 300,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  "reportCard".tr,
                  style: PoppinsCustomTextStyle.medium.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.white),
                ),
              ),
            ),
          ),
          Container(
            width: 300,
            decoration: const BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: SizedBox(
                height: 150,
                width: 270,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 15,
                      left: selectedLanguage == 'en' ? 20 : 0,
                      right: selectedLanguage == 'en' ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${"totalMarks".tr} :- ${totalMarks ?? "0"}",
                          style: PoppinsCustomTextStyle.regular.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black)),
                      const SizedBox(height: 10),
                      Text("${"obtainedMarks".tr} :- ${obtainedMarks ?? "0"}",
                          style: PoppinsCustomTextStyle.regular.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black)),
                      const SizedBox(height: 10),
                      Text("${"grade".tr} :- ${grade ?? ""}",
                          style: PoppinsCustomTextStyle.regular.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black)),
                      const SizedBox(height: 10),
                      Text("${"activity".tr} :- ${activity ?? ""}",
                          style: PoppinsCustomTextStyle.regular.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black)),
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }

  Widget topTabBar(bool isMobile) {
    return Center(
        child: Row(
      children: [
        tabTitle("academicData", StudentsFor.academic, 0, isMobile),
        tabTitle("teachingPlans", StudentsFor.teachingPlan, 1, isMobile),
        tabTitle("observation", StudentsFor.observation, 2, isMobile),
        tabTitle("progress", StudentsFor.progress, 3, isMobile),
      ],
    ));
  }

  fetchNewData(String fromDate, String toDate) async {
    int? code = await masterViewModel.fetchProgressData(
        widget.studentId ?? "", fromDate, toDate);
    if (code == 200) {
      print("Success Progess detail");
    } else {
      print("Failed Progress error : ${masterViewModel.apiError}");
    }
  }

  String? firstDateStr;
  String? lastDateStr;
  Map<String, bool> subjectVisibility = {};
  Map<String, Color> subjectColors = {};
  changeTabAction(StudentsFor type) async {
    masterViewModel.selectedType = type;
    if (masterViewModel.selectedType == StudentsFor.academic) {
    } else if (masterViewModel.selectedType == StudentsFor.teachingPlan) {
    } else if (masterViewModel.selectedType == StudentsFor.observation) {
    } else {
      loadCurriculum();
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final formatter = DateFormat('yyyy-MM-dd');
      firstDateStr = formatter.format(firstDay);
      lastDateStr = formatter.format(lastDay);
      firstDate = lastDateStr;
      lastDate = firstDateStr;
      fetchNewData(firstDateStr.toString(), lastDateStr.toString());
      for (var sp in masterViewModel.subjectPercentages) {
        subjectVisibility[sp.subject] = true;
      }
    }
  }

  tabTitle(text, StudentsFor type, int selectedTab, bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    bool isSelected = type == masterViewModel.selectedType;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            changeTabAction(type);
            masterViewModel.selectedTab = selectedTab;
          });
        },
        child: Container(
          width: 60,
          // height: 40,
          decoration: BoxDecoration(
              color: isSelected == true
                  ? AppColor.buttonGreen
                  : AppColor.lightYellow,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5), topRight: Radius.circular(5))),
          child: Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 7),
            child: Center(
              child: Text("$text".tr,
                  textAlign: TextAlign.center,
                  style: PoppinsCustomTextStyle.bold.copyWith(
                      fontSize: isMobile
                          ? fontSizeProvider.fontSize - 2
                          : fontSizeProvider.fontSize + 1,
                      color: AppColor.white)),
            ),
          ),
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

  String _formatTableDate(String raw) {
    if (raw.trim().isEmpty) return "-";
    final normalized = raw.trim().replaceAll(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      final dateOnly = raw.split('T').first.trim();
      return dateOnly.isEmpty ? raw : dateOnly;
    }
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  Widget detailsViewUI() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              decoration: BoxDecoration(
                  color: themeManager.isHighContrast
                      ? AppColor.labelText
                      : AppColor.white,
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    "${"date".tr} ${formatDate(date.toString())}",
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(height: 5),
                                Text("${"subjectTitle".tr} $subjectName",
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
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
                              Text(
                                  "${"date".tr} ${formatDate(date.toString())}",
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black)),
                              Text("${"subjectTitle".tr} $subjectName",
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black)),
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
                      height: 344,
                      decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              width: 1, color: AppColor.buttonGreen)),
                      child: TextField(
                        readOnly: true,
                        style: NotoSansArabicCustomTextStyle.bold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: description ?? "",
                            hintStyle: NotoSansArabicCustomTextStyle.bold
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black),
                            contentPadding: EdgeInsets.only(
                                left: selectedLanguage == 'en' ? 15 : 0,
                                right: selectedLanguage == 'en' ? 0 : 15)),
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

  bool showFullList = false;

  Widget observationTab(bool isMobile) {
    // int displayCount =
    //     showFullList ? masterViewModel.observationsList.length : 5 ;
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return Container(
        decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5))),
        child: isViewDetails == true
            ? detailsViewUI()
            : masterViewModel.observationsList.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No Observation"),
                  ))
                : Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 7 : 17, right: isMobile ? 7 : 17),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: masterViewModel.observationsList.length,
                      itemBuilder: (context, index) {
                        final sortedList = List<Map<dynamic, dynamic>>.from(
                            masterViewModel.observationsList)
                          ..sort((a, b) {
                            final aDate =
                                DateTime.tryParse((a['date'] ?? '').toString());
                            final bDate =
                                DateTime.tryParse((b['date'] ?? '').toString());
                            if (aDate == null && bDate == null) return 0;
                            if (aDate == null) return 1;
                            if (bDate == null) return -1;
                            return bDate.compareTo(aDate);
                          });

                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Container(
                            // height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: themeManager.isHighContrast
                                    ? AppColor.lightGrey
                                    : AppColor.white,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 15,
                                      offset: Offset(0, 10),
                                      color: AppColor.blueShadow)
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8, bottom: 8, right: 20, left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${"date".tr} ${formatDate(sortedList[index]['date'])}",
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(height: 7),
                                  Text(
                                    (sortedList[index]['observation'] ?? "")
                                        .toString(),
                                    softWrap: true,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black),
                                  ),
                                  const SizedBox(height: 7),
                                  if (isMobile)
                                    Text(
                                      "${"subject".tr} : ${sortedList[index]['subject']}",
                                      softWrap: true,
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black),
                                    ),
                                  if (isMobile) const SizedBox(height: 8),
                                  isMobile
                                      ? AppFillButton3(
                                          onPressed: () {
                                            setState(() {
                                              isViewDetails = true;
                                              date = sortedList[index]['date'];
                                              subjectName =
                                                  sortedList[index]['subject'];
                                              description = sortedList[index]
                                                  ['observation'];
                                            });
                                          },
                                          text: "viewObservation",
                                          color: AppColor.buttonGreen)
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${"subject".tr} : ${sortedList[index]['subject']}",
                                                softWrap: true,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    NotoSansArabicCustomTextStyle
                                                        .medium
                                                        .copyWith(
                                                            fontSize:
                                                                fontSizeProvider
                                                                    .fontSize,
                                                            color:
                                                                AppColor.black),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            AppFillButton3(
                                                onPressed: () {
                                                  setState(() {
                                                    isViewDetails = true;
                                                    date = sortedList[index]
                                                        ['date'];
                                                    subjectName =
                                                        sortedList[index]
                                                            ['subject'];
                                                    description =
                                                        sortedList[index]
                                                            ['observation'];
                                                  });
                                                },
                                                text: "viewObservation",
                                                color: AppColor.buttonGreen)
                                          ],
                                        )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ));
  }

  Widget discardButton(Function() onTap) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        height: 40,
        width: 150,
        decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColor.buttonGreen, width: 1)),
        child: Center(
          child: Text(
            "discard".tr,
            style: PoppinsCustomTextStyle.medium.copyWith(
                fontSize: fontSizeProvider.fontSize,
                color: AppColor.buttonGreen),
          ),
        ),
      ),
    );
  }

  bool isShowPlan = false;
  int? selectedIndex;
  Widget teachingPlans(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    // List teachingPlansSorted = List.from(masterViewModel.teachingPlans)
    //   ..sort((a, b) =>
    //       DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return Container(
      decoration: const BoxDecoration(
          color: AppColor.extralightGrey,
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5))),
      child: masterViewModel.teachingPlans.isEmpty
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("noTeachingPlan".tr),
            ))
          : Padding(
              padding: EdgeInsets.only(
                  left: isMobile ? 7 : 20, right: isMobile ? 7 : 20),
              child: Column(
                children: [
                  for (int index = 0;
                      index < masterViewModel.teachingPlans.length;
                      index++)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: themeManager.isHighContrast
                                ? AppColor.lightGrey
                                : AppColor.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 5,
                                color: AppColor.greyShadow,
                                offset: Offset(0, 5),
                              )
                            ],
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "examName".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 15,
                                                    color: AppColor.black),
                                          ),
                                          Text(
                                            "${masterViewModel.teachingPlans[index]['exam_name']}",
                                            style: NotoSansArabicCustomTextStyle
                                                .regular
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "subjectName".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 15,
                                                    color: AppColor.black),
                                          ),
                                          Text(
                                            " ${masterViewModel.teachingPlans[index]['subject']}",
                                            style: NotoSansArabicCustomTextStyle
                                                .regular
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "${"curriculumName".tr} : ",
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 15,
                                                    color: AppColor.black),
                                          ),
                                          Text(
                                            "${masterViewModel.teachingPlans[index]['curriculum_name']}",
                                            style: NotoSansArabicCustomTextStyle
                                                .regular
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      isMobile
                                          ? Row(
                                              children: [
                                                Text(
                                                  "${"examDate".tr} : ",
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .bold
                                                          .copyWith(
                                                              fontSize: 15,
                                                              color: AppColor
                                                                  .black),
                                                ),
                                                Text(
                                                  // formatDate(
                                                  masterViewModel
                                                          .teachingPlans[index]
                                                      ['date'],
                                                  // ),
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .regular
                                                          .copyWith(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .black),
                                                )
                                              ],
                                            )
                                          : const SizedBox(),
                                      const SizedBox(height: 5),
                                      isMobile
                                          ? InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedIndex =
                                                      selectedIndex == index
                                                          ? null
                                                          : index;
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Text("viewPlan".tr,
                                                      style: NotoSansArabicCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize: 16,
                                                              color: AppColor
                                                                  .buttonGreen)),
                                                  const SizedBox(width: 5),
                                                  selectedIndex == index
                                                      ? const Icon(Icons
                                                          .keyboard_arrow_up)
                                                      : const Icon(Icons
                                                          .keyboard_arrow_down),
                                                  // Icon(Icons.keyboard_arrow_up)
                                                ],
                                              ),
                                            )
                                          : const SizedBox()
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const SizedBox(height: 5),
                                      isMobile
                                          ? const SizedBox()
                                          : Row(
                                              children: [
                                                Text(
                                                  "${"examDate".tr} : ",
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .bold
                                                          .copyWith(
                                                              fontSize: 15,
                                                              color: AppColor
                                                                  .black),
                                                ),
                                                Text(
                                                  // formatDate(
                                                  masterViewModel
                                                          .teachingPlans[index]
                                                      ['date']
                                                  // )
                                                  ,
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .regular
                                                          .copyWith(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .black),
                                                )
                                              ],
                                            ),
                                      const SizedBox(height: 5),
                                      isMobile
                                          ? const SizedBox()
                                          : InkWell(
                                              onTap: () {
                                                setState(() {
                                                  selectedIndex =
                                                      selectedIndex == index
                                                          ? null
                                                          : index;
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Text("viewPlan".tr,
                                                      style: NotoSansArabicCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize: 16,
                                                              color: AppColor
                                                                  .buttonGreen)),
                                                  const SizedBox(width: 5),
                                                  selectedIndex == index
                                                      ? const Icon(Icons
                                                          .keyboard_arrow_up)
                                                      : const Icon(Icons
                                                          .keyboard_arrow_down),
                                                  // Icon(Icons.keyboard_arrow_up)
                                                ],
                                              ),
                                            ),
                                      const SizedBox(height: 5),
                                    ],
                                  )
                                ],
                              ),
                              if (selectedIndex == index)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    children: [
                                      const Divider(
                                        color: AppColor.buttonGreen,
                                        thickness: 1.2,
                                        height: 0.9,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${"learningObjectives".tr} : ",
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "${masterViewModel.teachingPlans[index]['plan_details']['learningObjectives']}"
                                                  .replaceAll('{', "")
                                                  .replaceAll('}', ''),
                                              textAlign: TextAlign.start,
                                              softWrap: true,
                                              // maxLines: 5,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColor.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${"instructionalStrategies".tr} : ",
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "${masterViewModel.teachingPlans[index]['plan_details']['instructionalStrategies']}"
                                                  .replaceAll('{', "")
                                                  .replaceAll('}', ''),
                                              textAlign: TextAlign.start,
                                              softWrap: true,
                                              // maxLines: 5,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColor.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "assessmentMethods".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          ),
                                          Expanded(
                                            child: Text(
                                              " ${masterViewModel.teachingPlans[index]['plan_details']['assessmentMethods']}"
                                                  .replaceAll('{', "")
                                                  .replaceAll('}', ''),
                                              textAlign: TextAlign.start,
                                              softWrap: true,
                                              // maxLines: 5,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColor.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${"recommendedResources".tr} : ",
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "${masterViewModel.teachingPlans[index]['plan_details']['recommendedResources']}"
                                                  .replaceAll('{', "")
                                                  .replaceAll('}', ''),
                                              textAlign: TextAlign.start,
                                              softWrap: true,
                                              // maxLines: 5,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColor.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "timeline".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black),
                                          ),
                                          Expanded(
                                            child: Text(
                                              " ${masterViewModel.teachingPlans[index]['plan_details']['timeline']}"
                                                  .replaceAll('{', "")
                                                  .replaceAll('}', ''),
                                              textAlign: TextAlign.start,
                                              softWrap: true,
                                              // maxLines: 5,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColor.black),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  Widget progressTab(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      decoration: BoxDecoration(
          color: themeManager.isHighContrast
              ? AppColor.grey
              : AppColor.extralightGrey,
          borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5))),
      child: Column(
        children: [
          const SizedBox(height: 20),
          isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 10),
                  Text("${"startDate".tr} : ",
                      style: PoppinsCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 10),
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
                          hintText: "$lastDate",
                          icon: null)),
                  const SizedBox(height: 10),
                  Text("${"endDate".tr} : ",
                      style: PoppinsCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 10),
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
                          hintText: "$firstDate",
                          icon: null)),
                ])
              : Row(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        Text("${"startDate".tr} : ",
                            style: PoppinsCustomTextStyle.medium.copyWith(
                                fontSize: fontSizeProvider.fontSize,
                                color: AppColor.black)),
                        const SizedBox(width: 10),
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
                                hintText: "$lastDate",
                                icon: null)),
                        const SizedBox(width: 25),
                      ],
                    ),
                    Row(
                      children: [
                        Text("${"endDate".tr} : ",
                            style: PoppinsCustomTextStyle.medium.copyWith(
                                fontSize: fontSizeProvider.fontSize,
                                color: AppColor.black)),
                        const SizedBox(width: 10),
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
                                hintText: "$firstDate",
                                icon: null)),
                      ],
                    )
                  ],
                ),
          const SizedBox(height: 25),
          // isMobile
          //     ?
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                gradeChart(),
                const SizedBox(height: 20),
                subjectPerformanceChart(),
                const SizedBox(height: 20),
                studentMarksTable(),
                const SizedBox(height: 20),
                improvement(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: AppFillButton3(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AnalyzeReportScreen(
                                    studentId: widget.studentId ?? "",
                                  )));
                    },
                    text: "analyzeReport",
                    color: AppColor.buttonGreen),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                    onSelected: (value) {
                      print('Selected Export: $value');
                    },
                    itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                              value: "Option 1",
                              onTap: () {
                                isDatafilter == true
                                    ? exportWithPdf(fromDateController.text,
                                        toDateController.text)
                                    : exportWithPdf(firstDateStr.toString(),
                                        lastDateStr.toString());
                                ;
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
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
                                          fontSize: 16,
                                          color: AppColor.white)))),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool isShowall = false;
  Widget studentMarksTable() {
    List<DataRow> rows = [];
    masterViewModel.fullDataTableEntries.map((entry) {
      return rows.add(DataRow(cells: [
        DataCell(Text(entry.subject)),
        DataCell(Text(entry.marks.toString())),
        DataCell(Text(entry.totalMarks.toString())),
        DataCell(Text(_formatTableDate(entry.timestamp.toString()))),
      ]));
    }).toList();
    return Column(
      children: [
        masterViewModel.fullDataTableEntries.isEmpty
            ? SizedBox()
            : SizedBox(
                width: MediaQuery.of(context).size.width / 1.4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => AppColor.buttonGreen), // Header row color
                    decoration: BoxDecoration(
                      border: Border.all(width: 0.8, color: AppColor.black),
                    ),
                    columns: [
                      DataColumn(
                          label: Text("subject".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: 15, color: AppColor.white))),
                      DataColumn(
                          label: Text("obtainedMarks".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: 15, color: AppColor.white))),
                      DataColumn(
                          label: Text("totalMarks".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: 15, color: AppColor.white))),
                      DataColumn(
                          label: Text("dateTitle".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: 15, color: AppColor.white))),
                    ],
                    rows: isShowall ? rows : rows.take(5).toList(),
                  ),
                ),
              ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
              onPressed: () {
                setState(() {
                  isShowall = !isShowall;
                });
              },
              child: Text(isShowall ? "showLess".tr : "showMore".tr,
                  style: NotoSansArabicCustomTextStyle.medium
                      .copyWith(fontSize: 15, color: AppColor.buttonGreen))),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Map<String, bool> subjectVisibilitySubject = {};
  Map<String, Color> subjectColorsSubject = {};

  Widget subjectPerformanceChart() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    // Initialize all subjects as visible if not already present
    if (subjectVisibilitySubject.isEmpty) {
      for (var sp in masterViewModel.subjectPercentages) {
        subjectVisibilitySubject[sp.subject] = true;
      }
    }

    // Filter visible subjects
    final visibleSubjects = masterViewModel.subjectPercentages
        .where((sp) => subjectVisibilitySubject[sp.subject] ?? true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
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
              color: AppColor.white,
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
                    primaryXAxis: const CategoryAxis(),
                    primaryYAxis: const NumericAxis(
                      minimum: 0,
                      maximum: 100,
                      interval: 20,
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<SubjectPercentage, String>(
                        dataSource: visibleSubjects,
                        xValueMapper: (SubjectPercentage data, _) =>
                            data.subject,
                        yValueMapper: (SubjectPercentage data, _) =>
                            data.percentage,
                        pointColorMapper: (SubjectPercentage data, int index) {
                          final originalIndex = masterViewModel
                              .subjectPercentages
                              .indexWhere((sp) => sp.subject == data.subject);
                          return masterViewModel.colors[
                              originalIndex % masterViewModel.colors.length];
                        },
                        width: visibleSubjects.length == 1 ? 0.3 : 0.8,
                        spacing: visibleSubjects.length == 1 ? 0.5 : 0.2,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox List
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: masterViewModel.subjectPercentages
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final sp = entry.value;
                    final isVisible =
                        subjectVisibilitySubject[sp.subject] ?? true;
                    final baseColor = masterViewModel
                        .colors[index % masterViewModel.colors.length];
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
                          style: TextStyle(color: displayColor),
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

  Widget improvement() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
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
                "improvement".tr,
                style: PoppinsCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize, color: AppColor.white),
              ),
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width / 1.4,
          decoration: const BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: subjectDropDown(),
              ),
              SizedBox(height: 10),
              // improvement text
              areasForImprovement.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text("noImprovement".tr),
                    ))
                  : Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   "areasforImprovement".tr,
                          //   style: NotoSansArabicCustomTextStyle.medium
                          //       .copyWith(fontSize: 15, color: AppColor.black),
                          // ),
                          const SizedBox(height: 10),
                          ...areasForImprovement
                              .map((area) => Text(area))
                              .toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
              SizedBox(height: 10),
            ],
          ),
        )
      ],
    );
  }

  Widget subjectDropDown() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;
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

  String formatTimestamp(String timestamp) {
    // Parse the timestamp
    DateTime dateTime = DateTime.parse(timestamp);

    // Format the date
    String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

    return formattedDate;
  }

  Set<String> selectedSubjects = {}; // replace selectedSubject with this

  Widget gradeChart() {
    final uniqueSubjects =
        masterViewModel.subjectNewData.map((sp) => sp.subject).toSet().toList();

    // Assign colors once
    if (subjectColors.isEmpty) {
      for (int i = 0; i < uniqueSubjects.length; i++) {
        subjectColors[uniqueSubjects[i]] =
            masterViewModel.colors[i % masterViewModel.colors.length];
      }
      selectedSubjects = uniqueSubjects.toSet();
    }

    // Group subject -> unique date records (keep latest per date)
    final Map<String, Map<DateTime, LineGraphModel>> groupedDataByDate = {};
    for (var entry in masterViewModel.subjectNewData) {
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
        color: AppColor.white,
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
              ),
              primaryYAxis: const NumericAxis(
                minimum: 0,
                maximum: 100,
                interval: 20,
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
                    Text(subject),
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

  selectFromDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      });
      toDateController
        ..text = DateFormat('yyyy-MM-dd').format(_selectedTDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: toDateController.text.length,
            affinity: TextAffinity.upstream));
      fetchNewData(fromDateController.text, toDateController.text);
    }
  }

  Future<void> fetchImprovementAreas(String subjectName) async {
    String apiUrl =
        "${Config.baseURL}student/area_need_improvement?studentId=${widget.studentId}&subjectName=$subjectName&lang=$selectedLanguage";
    masterViewModel.setLoading(true);
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
          masterViewModel.setLoading(false);
          // fetchSelectSubject = null;
        });
        masterViewModel.setLoading(false);
      } else {
        print("${response.statusCode} : ${response.body}");
        isLoading = false;
        masterViewModel.setLoading(false);
      }
    } catch (e) {
      setState(() {
        areasForImprovement.clear();
        errorMessage = "Error: ${e.toString()}";
        masterViewModel.setLoading(false);
      });
      print("Error: $e");
    }
  }
}
