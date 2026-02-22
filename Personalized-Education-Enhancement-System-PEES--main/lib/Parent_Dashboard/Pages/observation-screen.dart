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
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Models/observation_model.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppSection.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObservationScreenParent extends StatefulWidget {
  final String? studentId;
  final String? userName;
  final String? photoUrl;
  final String? teacherName;
  final String? grade;
  final String? className;
  final String? email;
  ObservationScreenParent({
    required this.studentId,
    required this.userName,
    required this.photoUrl,
    required this.teacherName,
    required this.grade,
    required this.className,
    required this.email,
    super.key,
  });

  @override
  State<ObservationScreenParent> createState() =>
      _ObservationScreenParentState();
}

class _ObservationScreenParentState extends State<ObservationScreenParent> {
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
  List<String> curriculumNames = [];
  String? imageUrl;
  TextEditingController _searchSubjectController = TextEditingController();
  String _searchQuery = "";

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
        _obsSelectedDate = newSelectedDate;
      });
      obsdateController
        ..text = DateFormat('dd-MM-yyyy').format(_obsSelectedDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: obsdateController.text.length,
            affinity: TextAffinity.upstream));
    }
  }

  fetchObservation() async {
    int? code = await viewModel.getObservationList(widget.studentId ?? "");
  }

  loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String url = '${Config.baseURL}curriculum?teacherId=$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> curriculumJson = data['curriculum'];
        curriculumList =
            curriculumJson.map((json) => Curriculum.fromJson(json)).toList();

        // Filter by grade
        filteredCurriculumList = curriculumList
            .where((item) =>
                item.grade.toLowerCase() == widget.grade?.toLowerCase())
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
    String studId = widget.studentId.toString() ?? "";
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

    if (observation.isEmpty) {
      Utils.snackBar("Please enter an observation", context);
      return;
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

    int? code =
        await viewModel.addObservation(studId, file, subject, observation, apiDate);
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
    obsdateController.clear();
    _trxnStatus = null;
    file = null;
  }

  @override
  void initState() {
    fetchObservation();
    // fetchSubjectList();
    loadCurriculum();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
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
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Container(
                                                      height: 60,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                          color: themeManager
                                                                  .isHighContrast
                                                              ? AppColor
                                                                  .labelText
                                                              : AppColor.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: AppColor
                                                                  .greyShadow,
                                                              blurRadius: 15,
                                                              offset:
                                                                  Offset(0, 10),
                                                            ),
                                                          ]),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: SizedBox(
                                                              child: TextField(
                                                                controller:
                                                                    _searchSubjectController,
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    _searchQuery = value
                                                                        .trim()
                                                                        .toLowerCase();
                                                                  });
                                                                },
                                                                style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                    color: themeManager.isHighContrast
                                                                        ? AppColor
                                                                            .black
                                                                        : AppColor
                                                                            .labelText,
                                                                    fontSize:
                                                                        fontSizeProvider.fontSize +
                                                                            1),
                                                                decoration: InputDecoration(
                                                                    border: InputBorder
                                                                        .none,
                                                                    hintStyle: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                        color: themeManager.isHighContrast
                                                                            ? AppColor
                                                                                .black
                                                                            : AppColor
                                                                                .labelText,
                                                                        fontSize:
                                                                            fontSizeProvider.fontSize +
                                                                                1),
                                                                    hintText:
                                                                        "searchSubject"
                                                                            .tr,
                                                                    contentPadding: EdgeInsets.only(
                                                                        left: selectedLanguage ==
                                                                                'en'
                                                                            ? 20
                                                                            : 0,
                                                                        right: selectedLanguage ==
                                                                                'en'
                                                                            ? 0
                                                                            : 20)),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            height: 60,
                                                            width: 60,
                                                            decoration:
                                                                BoxDecoration(
                                                                    color: AppColor
                                                                        .buttonGreen,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .only(
                                                                      bottomRight: Radius.circular(selectedLanguage ==
                                                                              'en'
                                                                          ? 10
                                                                          : 0),
                                                                      topRight: Radius.circular(selectedLanguage ==
                                                                              'en'
                                                                          ? 10
                                                                          : 0),
                                                                      bottomLeft: Radius.circular(selectedLanguage ==
                                                                              'en'
                                                                          ? 0
                                                                          : 10),
                                                                      topLeft: Radius.circular(selectedLanguage ==
                                                                              'en'
                                                                          ? 0
                                                                          : 10),
                                                                    )),
                                                            child:
                                                                const Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          12.0),
                                                              child: Icon(
                                                                  Icons.search,
                                                                  size: 30,
                                                                  color: AppColor
                                                                      .white),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        isMobile ? 420 : 520,
                                                    child:
                                                        SingleChildScrollView(
                                                      child: obsList(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
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
                  color: AppColor.white,
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
                      decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              width: 1, color: AppColor.buttonGreen)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          description ?? "",
                          style: NotoSansArabicCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black),
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
                                    NetworkImage(widget.photoUrl ?? "")),
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 10),
                  Text(widget.userName ?? "",
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"email".tr} ${widget.email ?? ""}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text(widget.className ?? "",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"grade".tr} : ${widget.grade ?? ""}",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
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
                          backgroundImage: NetworkImage(widget.photoUrl ?? "")),
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
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    final sortedList = viewModel.observationsList
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    // 🔍 Apply filter based on search subject
    final filteredList = sortedList.where((observation) {
      final subject = (observation['subject'] ?? "").toString().toLowerCase();
      return _searchQuery.isEmpty || subject.contains(_searchQuery);
    }).toList();
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          for (int i = 0; i < filteredList.length; i++)
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
                    color: AppColor.white,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${"date".tr} ${formatDate(filteredList[i]['date'])}",
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.black)),
                          const SizedBox(height: 7),
                          Text(filteredList[i]['observation'],
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.black)),
                          const SizedBox(height: 7),
                          isMobile
                              ? Text(
                                  "${"subject".tr} : ${filteredList[i]['subject']}",
                                  style: NotoSansArabicCustomTextStyle.medium
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black))
                              : SizedBox(),
                          isMobile ? const SizedBox(height: 5) : SizedBox(),
                          isMobile
                              ? AppFillButton3(
                                  onPressed: () {
                                    setState(() {
                                      isViewDetails = true;
                                      date = filteredList[i]['date'];
                                      subjectName = filteredList[i]['subject'];
                                      description =
                                          filteredList[i]['observation'];
                                      imageUrl = filteredList[i][
                                          'attachment_url']; // <-- Add this line
                                    });
                                  },
                                  text: "viewObservation",
                                  color: AppColor.buttonGreen)
                              : SizedBox()
                        ],
                      ),
                      isMobile
                          ? SizedBox()
                          : Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                    "${"subject".tr} : ${filteredList[i]['subject']}",
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                              )),
                      isMobile
                          ? SizedBox()
                          : AppFillButton3(
                              onPressed: () {
                                setState(() {
                                  isViewDetails = true;
                                  date = filteredList[i]['date'];
                                  subjectName = filteredList[i]['subject'];
                                  description = filteredList[i]['observation'];
                                  imageUrl = filteredList[i]
                                      ['attachment_url']; // <-- Add this line
                                });
                              },
                              text: "viewObservation",
                              color: AppColor.buttonGreen)
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
                      color: AppColor.black)),
              const SizedBox(width: 20),
              Container(
                  height: 200,
                  width: 668,
                  decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "List of Notes for student",
                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black),
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
                      color: AppColor.black)),
              const SizedBox(width: 75),
              Container(
                  height: 200,
                  width: 668,
                  decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Provided Feedback",
                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
