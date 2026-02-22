import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Pages/Teaching_Plans/viewAllFeedback_screen.dart';
import 'package:pees/Teacher_Dashbord/Pages/Teaching_Plans/viewAllplan_screen.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeachingPlanScreen extends StatefulWidget {
  StudentModel? model;
  TeachingPlanScreen({this.model, super.key});

  @override
  State<TeachingPlanScreen> createState() => _TeachingPlanScreenState();
}

class _TeachingPlanScreenState extends State<TeachingPlanScreen> {
  TeacherService viewModel = TeacherService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  TextEditingController subjectController = TextEditingController();
  TextEditingController feedBackController = TextEditingController();
  TextEditingController editObjectController = TextEditingController();
  TextEditingController editStrategiesController = TextEditingController();
  TextEditingController editResourceController = TextEditingController();
  TextEditingController editMethodController = TextEditingController();
  TextEditingController timeLineController = TextEditingController();
  bool isEditPlan = false;
  bool isFeedback = false;
  String? learningObjectives;
  String? instructionalStrategies;
  String? resourcesMaterials;
  String? additionalSupport;
  String? timeline;
  List<Curriculum> curriculumList = [];
  List<Curriculum> filteredCurricula = [];
  List<String> filterSubject = [];
  bool isSubjectSelect = false;
  String? selectedSubject;
  String message = "";
  String? fetchedPlanId;

  updateTeachingPlan() async {
    String grade = widget.model?.grade ?? "";
    print("Grade :  $grade");

    // Convert text inputs into Map<String, String>
    Map<String, String> object = {"objective1": editObjectController.text};

    Map<String, String> strategies = {
      "strategy1": editStrategiesController.text
    };

    Map<String, String> resource = {"resource1": editResourceController.text};

    Map<String, String> method = {"method1": editMethodController.text};

    Map<String, String> timeline = {"week1": timeLineController.text};

    int? code = await viewModel.updateTeachingPlan(
      widget.model?.studentId ?? "",
      fetchedPlanId ?? "",
      widget.model?.studentName ?? "",
      widget.model?.grade ?? "",
      object,
      strategies,
      resource,
      method,
      timeline,
      widget.model?.version ?? 0,
    );

    if (context.mounted) {
      if (code == 200) {
        setState(() {
          print("Update Object : $object");
          print("Update strategies : $strategies");
          print("Update resource : $resource");
          print("Update method : $method");
          print("Update timeline : $timeline");
          isEditPlan = false;
          fetchTeachingPlan(selectedSubject.toString());
        });
        Utils.snackBar("successTeachingPlan".tr, context);
      } else {
        print("${viewModel.apiError}");
        Utils.snackBar("${viewModel.apiError}", context);
      }
    }
  }

  String? fileUrl;
  void downloadFile(String url) async {
    final anchorElement = html.AnchorElement(href: url)
      ..setAttribute("download", "teaching_plan.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);

    //  String fileName = url.split('/').last;
    // html.AnchorElement anchorElement = new html.AnchorElement(href: url);
    // anchorElement.download = "teaching_plan";
    // anchorElement.click();
  }

  downloadAction() async {
    String? studID = widget.model?.studentId;
    String? planId = fetchedPlanId ?? "";
    print("PlanID : $planId");
    print("StudID : $studID");
    String? url = await viewModel.exportTeachingPlan(
        studID ?? "", planId ?? "", selectedLanguage);
    if (context.mounted) {
      if (url != null) {
        setState(() {
          fileUrl = url;
          downloadFile(fileUrl!);
        });
        Utils.snackBar("downloadPlan".tr, context);
      } else {
        Utils.snackBar("${viewModel.apiError}", context);
      }
    }
  }

  Future<int?> getTeachingPlan(
      String studId, String planId, String selectedSubject) async {
    viewModel.setLoading(
      true,
    );

    final url = Uri.parse(
      "${Config.baseURL}student/getTeachingPlan?subjectName=$selectedSubject&studentId=$studId&lang=$selectedLanguage",
    );

    try {
      print("Fetching URL: $url");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("API Response Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey("teaching_plan")) {
          final Map<String, dynamic> teachingPlan =
              jsonResponse["teaching_plan"];
          final Map<String, dynamic> actionPlan = teachingPlan;

          setState(() {
            final assessmentMap =
                Map<String, String>.from(actionPlan["assessmentMethods"] ?? {});
            final strategyMap = Map<String, String>.from(
                actionPlan["instructionalStrategies"] ?? {});
            final objectiveMap = Map<String, String>.from(
                actionPlan["learningObjectives"] ?? {});
            final resourceMap = Map<String, String>.from(
                actionPlan["recommendedResources"] ?? {});
            final timelineMap =
                Map<String, String>.from(actionPlan["timeline"] ?? {});

            additionalSupport = assessmentMap.values.join('\n\n');
            instructionalStrategies = strategyMap.values.join('\n\n');
            learningObjectives = objectiveMap.values.join('\n\n');
            resourcesMaterials = resourceMap.values.join('\n\n');
            timeline = timelineMap.values.join('\n\n');
// Save the fetched planId
            fetchedPlanId = teachingPlan["planId"] as String?;
            print("Fetched Plan ID: $fetchedPlanId");

            print("Assessment Methods: $additionalSupport");
            print("Instructional Strategies: $instructionalStrategies");
            print("Learning Objectives: $learningObjectives");
            print("Resources Materials: $resourcesMaterials");
            print("Timeline: $timeline");
          });

          viewModel.setLoading(false);
          viewModel.notifyListeners();
          return response.statusCode;
        } else {
          print("Error: 'teaching_plan' key not found.");
        }
      } else {
        print("Error: Failed with status code ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    } finally {
      viewModel.setLoading(false);
      viewModel.notifyListeners();
    }

    return null;
  }

  fetchTeachingPlan(String SelectedSubject) async {
    setState(() {
      additionalSupport = "";
      instructionalStrategies = "";
      learningObjectives = "";
      resourcesMaterials = "";
      timeline = "";

      editObjectController.clear();
      editMethodController.clear();
      editStrategiesController.clear();
      editResourceController.clear();
      timeLineController.clear();
      isSubjectSelect = false;
      message = "noTeachingPlan" ?? "";
    });

    String? studID = widget.model?.studentId;
    String? planID = widget.model?.planId;
    int? code = await getTeachingPlan(
        studID ?? "", planID ?? "", SelectedSubject.toString());
    print("Selected Get Plan Subject : $SelectedSubject");
    if (context.mounted) {
      if (code == 200) {
        print(" Teaching Plan fetched successfully");

        setState(() {
          editObjectController.text = learningObjectives ?? "";
          editMethodController.text = additionalSupport ?? "";
          editStrategiesController.text = instructionalStrategies ?? "";
          editResourceController.text = resourcesMaterials ?? "";
          timeLineController.text = timeline.toString();
          isSubjectSelect = true;

          // print(" Object : ${learningObjectives}");
          // print(" Method : ${additionalSupport}");
          // print(" Strategies : ${instructionalStrategies}");
          // print(" Resource : ${resourcesMaterials}");
          // print(" Timeline : ${timeline}");
        });
      } else {
        print(" Fetch failed: ${viewModel.apiError}");
        setState(() {
          isSubjectSelect = false;
          message = "noTeachingPlan" ?? "";
        });
      }
    }
  }

  feedbackSendAction() async {
    String feedback = feedBackController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    String planId = widget.model?.planId ?? "";
    String studId = widget.model?.studentId ?? "";
    print("Teacher ID : $teacherId");
    print("PlanId : $planId");
    if (feedback.isEmpty) {
      Utils.snackBar("feedbackEmpty".tr, context);
    } else {
      int? code = await viewModel.feedBackPlan(
          teacherId ?? "", planId, feedback, studId);
      if (context.mounted) {
        if (code == 200) {
          setState(() {
            isFeedback = false;
            Utils.snackBar("successFeedback".tr, context);
          });
        } else {
          print("Feedback send error : ${viewModel.apiError}");
          Utils.snackBar("${viewModel.apiError}", context);
        }
      }
    }
  }

  @override
  void initState() {
    loadCurriculum();
    // fetchTeachingPlan();
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
                                borderRadius: BorderRadius.circular(20),
                                color: themeManager.isHighContrast
                                    ? AppColor.labelText
                                    : AppColor.white,
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 15,
                                      color: AppColor.greyShadow,
                                      offset: Offset(0, 15))
                                ]),
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isMobile ? 8 : 70,
                                  right: isMobile ? 8 : 70),
                              child: Column(
                                children: [
                                  studentInformation(),
                                  const SizedBox(height: 30),
                                  teachingPlans(),
                                  const SizedBox(height: 30)
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget feedBackPlan(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        // Row(
        //   children: [
        //     Text("subjectTitle".tr,
        //         style: NotoSansArabicCustomTextStyle.semibold.copyWith(
        //             fontSize: fontSizeProvider.fontSize,
        //             color: AppColor.black)),
        //     const SizedBox(width: 20),
        //     Container(
        //       height: 38,
        //       width: 714,
        //       decoration: BoxDecoration(
        //           color: AppColor.white,
        //           borderRadius: BorderRadius.circular(10)),
        //       child: TextField(
        //         controller: subjectController,
        //         style: PoppinsCustomTextStyle.regular.copyWith(
        //             fontSize: fontSizeProvider.fontSize, color: AppColor.black),
        //         decoration: InputDecoration(
        //           border: InputBorder.none,
        //           hintText: "subjectFeedback".tr,
        //           contentPadding: const EdgeInsets.only(left: 33, bottom: 10),
        //           hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
        //               color: AppColor.labelText,
        //               fontSize: fontSizeProvider.fontSize),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("feedback".tr,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    fontSize: fontSizeProvider.fontSize,
                    color: AppColor.black)),
            const SizedBox(width: 5),
            Container(
              height: 200,
              width: 714,
              decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: feedBackController,
                style: PoppinsCustomTextStyle.regular.copyWith(
                    fontSize: fontSizeProvider.fontSize, color: AppColor.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "feedbackHint".tr,
                  contentPadding: const EdgeInsets.only(left: 33),
                  hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                      color: AppColor.labelText,
                      fontSize: fontSizeProvider.fontSize),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    // isEdit = false;
                    isFeedback = false;
                  });
                },
                child: Container(
                  height: isMobile ? 62 : 40,
                  width: 150,
                  decoration: BoxDecoration(
                      color: AppColor.lightYellow,
                      borderRadius: BorderRadius.circular(5)),
                  child: Center(
                    child: Text(
                      "cancel".tr,
                      style: PoppinsCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
              isMobile ? SizedBox(width: 20) : SizedBox(),
              AppFillButton3(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AllFeedbackScreen(
                                planId: widget.model?.planId ?? "")));
                  },
                  text: "viewAllFeedback",
                  color: AppColor.buttonGreen),
              isMobile ? SizedBox(width: 20) : SizedBox(),
              AppFillButton3(
                  onPressed: () {
                    feedbackSendAction();
                  },
                  text: "send",
                  color: AppColor.buttonGreen)
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
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
                  const SizedBox(height: 15),
                  Text(widget.model?.studentName ?? "",
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"email".tr} ${widget.model?.email ?? ""}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text(widget.model?.classSection ?? "",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"grade".tr} : ${widget.model?.grade ?? ""}",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            isMobile
                ? const SizedBox()
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

  Widget teachingPlans() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          Container(
              height: 40,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: AppColor.buttonGreen,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5))),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    "teachingPlans".tr,
                    style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: AppColor.white),
                  ),
                ),
              )),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                color: AppColor.extralightGrey,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: Padding(
              padding: EdgeInsets.only(
                  left: isMobile ? 10 : 38, right: isMobile ? 10 : 38),
              child: isEditPlan == true
                  ? isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: editPlan(isMobile))
                      : editPlan(isMobile)
                  : isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: teachingPlanViewDetails(isMobile),
                        )
                      : teachingPlanViewDetails(isMobile),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Future<void> loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      final response = await http
          .get(Uri.parse('${Config.baseURL}curriculum?teacherId=$userId'));
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
            selectedSubject = filterSubject.first;
            isSubjectSelect = true;
          } else {
            selectedSubject = null;
            isSubjectSelect = false;
          }
        });

        if (selectedSubject != null) {
          fetchTeachingPlan(selectedSubject!);
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

  Widget teachingPlanViewDetails(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(children: [
          Text("${"selectSubject".tr} : ",
              style: NotoSansArabicCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black)),
          const SizedBox(height: 5),
          subjectDropDown(isMobile),
        ]),
        isSubjectSelect == false
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("$message".tr),
              ))
            : Text(""),
        isSubjectSelect == true
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "objectives".tr,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 101,
                        width: 714,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              learningObjectives ?? "",
                              style: NotoSansArabicCustomTextStyle.regular
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.textGrey),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "strategies".tr,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                      ),
                      const SizedBox(width: 13),
                      Container(
                        height: 101,
                        width: 714,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              instructionalStrategies ?? "",
                              style: NotoSansArabicCustomTextStyle.regular
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.textGrey),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "resources".tr,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                      ),
                      const SizedBox(width: 13),
                      Container(
                        height: 101,
                        width: 714,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              resourcesMaterials ?? "",
                              style: NotoSansArabicCustomTextStyle.regular
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.textGrey),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "assessmentMethods".tr,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        height: 101,
                        width: 624,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              additionalSupport ?? "",
                              style: NotoSansArabicCustomTextStyle.regular
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.textGrey),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "timeline".tr,
                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.black),
                      ),
                      const SizedBox(width: 13),
                      Container(
                        height: 101,
                        width: 714,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 15),
                          child: SingleChildScrollView(
                            child: Text(
                              timeline ?? "",
                              style: NotoSansArabicCustomTextStyle.regular
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize,
                                      color: AppColor.textGrey),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppFillButton3(
                            onPressed: () {
                              setState(() {
                                isEditPlan = true;
                              });
                            },
                            text: "edit",
                            color: AppColor.lightYellow),
                        isMobile ? const SizedBox(width: 10) : const SizedBox(),
                        AppFillButton3(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ViewTeachingPlanScreen(
                                            studentId:
                                                widget.model?.studentId ?? '',
                                          )));
                            },
                            text: "viewAllPlans",
                            color: AppColor.buttonGreen),
                        // isMobile ? const SizedBox(width: 10) : const SizedBox(),
                        // AppFillButton3(
                        //     onPressed: () {
                        //       setState(() {
                        //         isFeedback = true;
                        //       });
                        //     },
                        //     text: "feedbackButton",
                        //     color: AppColor.buttonGreen),
                        isMobile ? const SizedBox(width: 10) : const SizedBox(),
                        AppFillButton3(
                            onPressed: () {
                              downloadAction();
                            },
                            text: "download",
                            color: AppColor.buttonGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              )
            : SizedBox(),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget subjectDropDown(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;
    if (selectedSubject != null && !filterSubject.contains(selectedSubject)) {
      selectedSubject = filterSubject.isNotEmpty ? filterSubject.first : null;
      isSubjectSelect = selectedSubject != null;
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
        value: selectedSubject, // Must be in subjects list
        items: filterSubject.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject, style: TextStyle(color: textColor)),
          );
        }).toList(),
        onChanged: (String? newSubject) {
          if (newSubject != null) {
            setState(() {
              selectedSubject = newSubject;
              isSubjectSelect = true;

              print("academic data subject = $selectedSubject");
            });
            fetchTeachingPlan(newSubject);
          }
        },
        validator: (value) => value == null ? "Please select a subject" : null,
      ),
    );
  }

  Widget dropDownBox() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColor.greyShadow,
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              "searchHint".tr,
              style: NotoSansArabicCustomTextStyle.bold
                  .copyWith(color: AppColor.labelText, fontSize: 18),
            ),
          ),
          Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  topRight: Radius.circular(10),
                )),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(AppImage.arrowDownWhite, width: 20),
            ),
          )
        ],
      ),
    );
  }

  Widget editPlan(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "objectives".tr,
              style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
            const SizedBox(width: 10),
            Container(
                height: 101,
                width: 714,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.white),
                child: TextField(
                  controller: editObjectController,
                  maxLines: 5,
                  style: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.labelText),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "",
                      contentPadding: EdgeInsets.only(left: 10, top: 5)),
                ))
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "strategies".tr,
              style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
            const SizedBox(width: 13),
            Container(
                height: 101,
                width: 714,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.white),
                child: TextField(
                  maxLines: 5,
                  controller: editStrategiesController,
                  style: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.labelText),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "",
                      contentPadding: EdgeInsets.only(left: 10, top: 5)),
                ))
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "resources".tr,
              style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
            const SizedBox(width: 13),
            Container(
                height: 101,
                width: 714,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.white),
                child: TextField(
                  maxLines: 5,
                  controller: editResourceController,
                  style: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.labelText),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "",
                      contentPadding: EdgeInsets.only(left: 10, top: 5)),
                ))
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "assessmentMethods".tr,
              style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
            const SizedBox(width: 4),
            Container(
                height: 101,
                width: 624,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.white),
                child: TextField(
                  maxLines: 5,
                  controller: editMethodController,
                  style: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.labelText),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "",
                      contentPadding: EdgeInsets.only(left: 10, top: 5)),
                ))
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "timeline".tr,
              style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
            const SizedBox(width: 13),
            Container(
                height: 101,
                width: 714,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.white),
                child: TextField(
                  maxLines: 5,
                  controller: timeLineController,
                  style: NotoSansArabicCustomTextStyle.regular.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.labelText),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "",
                      contentPadding: EdgeInsets.only(left: 10, top: 5)),
                ))
          ],
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    isEditPlan = false;
                  });
                },
                child: Container(
                  width: 140,
                  height: 37,
                  decoration: BoxDecoration(
                      border: Border.all(width: 2, color: AppColor.buttonGreen),
                      borderRadius: BorderRadius.circular(5)),
                  child: Center(
                    child: Text(
                      "cancel".tr,
                      style: PoppinsCustomTextStyle.semibold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.buttonGreen),
                    ),
                  ),
                ),
              ),
              isMobile ? const SizedBox(width: 10) : const SizedBox(),
              AppFillButton3(
                  onPressed: () {
                    updateTeachingPlan();
                  },
                  text: "saveChnages",
                  color: AppColor.buttonGreen),
            ],
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
