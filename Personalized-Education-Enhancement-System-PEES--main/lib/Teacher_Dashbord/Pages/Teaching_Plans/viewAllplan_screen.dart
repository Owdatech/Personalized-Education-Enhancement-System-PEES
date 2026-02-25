// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Teacher_Dashbord/Pages/Teaching_Plans/viewAllFeedback_screen.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewTeachingPlanScreen extends StatefulWidget {
  String? studentId;
  ViewTeachingPlanScreen({this.studentId, super.key});

  @override
  State<ViewTeachingPlanScreen> createState() => _ViewTeachingPlanScreenState();
}

class _ViewTeachingPlanScreenState extends State<ViewTeachingPlanScreen> {
  TeacherService viewModel = TeacherService();
  int? selectedIndex;
  int? selectedFeedbackIndex;

  fetchPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    int? code = await viewModel.fetchTeachingPlanForStudent(
        teacherId ?? "", widget.studentId ?? "");
    if (code == 200) {
      print("Teaching Plan successfully fetched");
    } else {
      print("teaching plan fetch error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchPlans();
    super.initState();
  }

  @override
  void dispose() {
    feedBackController.dispose();
    super.dispose();
  }

  bool isFeedback = false;

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          // List teachingPlansSorted = List.from(viewModel.teachingPlansList)
          //   ..sort((a, b) =>
          //       DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.bgLavender,
              body: SafeArea(
                child: Stack(
                  children: [
                    isMobile ? const SizedBox() : const BackButtonWidget(),
                    Padding(
                      padding: EdgeInsets.only(
                          top: 30,
                          left: isMobile ? 12 : 100,
                          right: isMobile ? 12 : 30),
                      child: Column(
                        children: [
                          isMobile
                              ? const BackButtonWidget()
                              : const SizedBox(),
                          SizedBox(height: isMobile ? 5 : 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "teachingPlans".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: 18,
                                      color: themeManager.isHighContrast
                                          ? AppColor.white
                                          : AppColor.buttonGreen),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: viewModel.teachingPlansList.isEmpty
                                ? Center(
                                    child: Text("norecordYet".tr),
                                  )
                                : Builder(builder: (BuildContext newContext) {
                                    return ListView.builder(
                                      itemCount:
                                          viewModel.teachingPlansList.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 7),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                                color: AppColor.panelDarkSoft,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    blurRadius: 5,
                                                    color: AppColor.greyShadow,
                                                    offset: Offset(0, 5),
                                                  )
                                                ],
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "${"examName".tr} ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            15,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Text(
                                                                "${viewModel.teachingPlansList[index]['exam_name']}",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .regular
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "${"subjectName".tr} ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            15,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Text(
                                                                "${viewModel.teachingPlansList[index]['subject']}",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .regular
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "${"curriculumName".tr} : ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            15,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Text(
                                                                "${viewModel.teachingPlansList[index]['curriculum_name']}",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .regular
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              )
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          isMobile
                                                              ? Row(
                                                                  children: [
                                                                    Text(
                                                                      "${"examDate".tr} : ",
                                                                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black),
                                                                    ),
                                                                    Text(
                                                                      // formatDate(
                                                                      viewModel.teachingPlansList[
                                                                              index]
                                                                          [
                                                                          'date'],
                                                                      // ),
                                                                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black),
                                                                    )
                                                                  ],
                                                                )
                                                              : const SizedBox(),
                                                          isMobile
                                                              ? const SizedBox(
                                                                  height: 5)
                                                              : const SizedBox(),
                                                          isMobile
                                                              ? InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      selectedIndex = selectedIndex ==
                                                                              index
                                                                          ? null
                                                                          : index;
                                                                    });
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Text(
                                                                          "viewPlan"
                                                                              .tr,
                                                                          style: NotoSansArabicCustomTextStyle.medium.copyWith(
                                                                              fontSize: 16,
                                                                              color: AppColor.buttonGreen)),
                                                                      const SizedBox(
                                                                          width:
                                                                              5),
                                                                      selectedIndex ==
                                                                              index
                                                                          ? const Icon(Icons
                                                                              .keyboard_arrow_up)
                                                                          : const Icon(
                                                                              Icons.keyboard_arrow_down),
                                                                      // Icon(Icons.keyboard_arrow_up)
                                                                    ],
                                                                  ),
                                                                )
                                                              : const SizedBox(),
                                                          const SizedBox(
                                                              height: 5),
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                selectedFeedbackIndex =
                                                                    selectedFeedbackIndex ==
                                                                            index
                                                                        ? null
                                                                        : index;
                                                              });
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: AppColor
                                                                      .white,
                                                                  border: Border.all(
                                                                      width:
                                                                          0.7,
                                                                      color: AppColor
                                                                          .buttonGreen),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Text(
                                                                  "sendFeedback"
                                                                      .tr,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .medium
                                                                      .copyWith(
                                                                          color: AppColor
                                                                              .buttonGreen,
                                                                          fontSize:
                                                                              13),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                        ],
                                                      ),
                                                      isMobile
                                                          ? const SizedBox()
                                                          : Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                const SizedBox(
                                                                    height: 5),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      "${"examDate".tr} : ",
                                                                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black),
                                                                    ),
                                                                    Text(
                                                                      // formatDate(
                                                                      viewModel.teachingPlansList[
                                                                              index]
                                                                          [
                                                                          'date'],
                                                                      // ),
                                                                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black),
                                                                    )
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                InkWell(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      selectedIndex = selectedIndex ==
                                                                              index
                                                                          ? null
                                                                          : index;
                                                                    });
                                                                  },
                                                                  child: Row(
                                                                    children: [
                                                                      Text(
                                                                          "viewPlan"
                                                                              .tr,
                                                                          style: NotoSansArabicCustomTextStyle.medium.copyWith(
                                                                              fontSize: 16,
                                                                              color: AppColor.buttonGreen)),
                                                                      const SizedBox(
                                                                          width:
                                                                              5),
                                                                      selectedIndex ==
                                                                              index
                                                                          ? const Icon(Icons
                                                                              .keyboard_arrow_up)
                                                                          : const Icon(
                                                                              Icons.keyboard_arrow_down),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                              ],
                                                            )
                                                    ],
                                                  ),
                                                  if (selectedFeedbackIndex ==
                                                      index)
                                                    SizedBox(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 5),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              color: AppColor
                                                                  .white,
                                                              border: Border.all(
                                                                  width: 0.7,
                                                                  color: AppColor
                                                                      .buttonGreen),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7)),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                        "feedback"
                                                                            .tr,
                                                                        style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                AppColor.black)),
                                                                    IconButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            selectedFeedbackIndex =
                                                                                null;
                                                                          });
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .cancel,
                                                                            weight:
                                                                                18))
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                Container(
                                                                  height: 60,
                                                                  decoration: BoxDecoration(
                                                                      color: AppColor
                                                                          .lightGrey,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                  child:
                                                                      TextField(
                                                                    controller:
                                                                        feedBackController,
                                                                    style: PoppinsCustomTextStyle
                                                                        .regular
                                                                        .copyWith(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                AppColor.black),
                                                                    decoration:
                                                                        InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      hintText:
                                                                          "feedbackHint"
                                                                              .tr,
                                                                      contentPadding: const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8),
                                                                      hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                                                                          color: AppColor
                                                                              .text,
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    AppFillButton3(
                                                                        onPressed:
                                                                            () {
                                                                          feedbackSendAction(viewModel.teachingPlansList[index]['plan_details']
                                                                              [
                                                                              'planId']);
                                                                        },
                                                                        text:
                                                                            "send",
                                                                        color: AppColor
                                                                            .buttonGreen),
                                                                    isMobile
                                                                        ? const SizedBox()
                                                                        : AppFillButton3(
                                                                            onPressed:
                                                                                () {
                                                                              print("Go Plan Id : ${viewModel.teachingPlansList[index]['plan_details']['planId']}");
                                                                              Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => AllFeedbackScreen(
                                                                                            planId: viewModel.teachingPlansList[index]['plan_details']['planId'],
                                                                                          )));
                                                                            },
                                                                            text:
                                                                                "viewAllFeedback",
                                                                            color:
                                                                                AppColor.buttonGreen),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 5),
                                                                isMobile
                                                                    ? AppFillButton3(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(builder: (context) => AllFeedbackScreen(planId: viewModel.teachingPlansList[index]['plan_details']['planId'])));
                                                                        },
                                                                        text:
                                                                            "viewAllFeedback",
                                                                        color: AppColor
                                                                            .buttonGreen)
                                                                    : const SizedBox()
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (selectedIndex == index)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: Column(
                                                        children: [
                                                          const Divider(
                                                            color: AppColor
                                                                .buttonGreen,
                                                            thickness: 1.2,
                                                            height: 0.9,
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${"learningObjectives".tr} : ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "${viewModel.teachingPlansList[index]['plan_details']['learningObjectives']}"
                                                                      .replaceAll(
                                                                          '{',
                                                                          "")
                                                                      .replaceAll(
                                                                          '}',
                                                                          ''),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  softWrap:
                                                                      true,
                                                                  // maxLines: 5,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${"instructionalStrategies".tr} : ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "${viewModel.teachingPlansList[index]['plan_details']['instructionalStrategies']}"
                                                                      .replaceAll(
                                                                          '{',
                                                                          "")
                                                                      .replaceAll(
                                                                          '}',
                                                                          ''),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  softWrap:
                                                                      true,
                                                                  // maxLines: 5,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${"assessmentMethods".tr} ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  " ${viewModel.teachingPlansList[index]['plan_details']['assessmentMethods']}"
                                                                      .replaceAll(
                                                                          '{',
                                                                          "")
                                                                      .replaceAll(
                                                                          '}',
                                                                          ''),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  softWrap:
                                                                      true,
                                                                  // maxLines: 5,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${"recommendedResources".tr} : ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "${viewModel.teachingPlansList[index]['plan_details']['recommendedResources']}"
                                                                      .replaceAll(
                                                                          '{',
                                                                          "")
                                                                      .replaceAll(
                                                                          '}',
                                                                          ''),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  softWrap:
                                                                      true,
                                                                  // maxLines: 5,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${"timeline".tr} ",
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: AppColor
                                                                            .black),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  " ${viewModel.teachingPlansList[index]['plan_details']['timeline']}"
                                                                      .replaceAll(
                                                                          '{',
                                                                          "")
                                                                      .replaceAll(
                                                                          '}',
                                                                          ''),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  softWrap:
                                                                      true,
                                                                  // maxLines: 5,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
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
                                        );
                                      },
                                    );
                                  }),
                          )
                        ],
                      ),
                    ),
                    value.loading ? const LoaderView() : Container()
                  ],
                ),
              ),
            );
          });
        }));
  }

  TextEditingController feedBackController = TextEditingController();
  void showAlerts(BuildContext context, String planId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          "sendFeedback".tr,
          style: NotoSansArabicCustomTextStyle.bold
              .copyWith(fontSize: 16, color: AppColor.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("feedback".tr,
                style: NotoSansArabicCustomTextStyle.semibold
                    .copyWith(fontSize: 14, color: AppColor.black)),
            const SizedBox(height: 5),
            Container(
              height: 60,
              decoration: BoxDecoration(
                  color: AppColor.panelDarkSoft,
                  borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: feedBackController,
                style: PoppinsCustomTextStyle.regular
                    .copyWith(fontSize: 14, color: AppColor.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "feedbackHint".tr,
                  contentPadding: const EdgeInsets.only(left: 8),
                  hintStyle: NotoSansArabicCustomTextStyle.regular
                      .copyWith(color: AppColor.labelText, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 5),
            AppFillButton3(
                onPressed: () {
                  feedbackSendAction(planId);
                },
                text: "send",
                color: AppColor.buttonGreen)
          ],
        ),
      ),
    );
  }

  feedbackSendAction(String planId) async {
    String feedback = feedBackController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    String? studentId = widget.studentId ?? "";
    print("Teacher ID : $teacherId");
    print("PlanId : $planId");
    if (feedback.isEmpty) {
      Utils.snackBar("feedbackEmpty".tr, context);
    } else {
      int? code = await viewModel.feedBackPlan(
          teacherId ?? "", planId, feedback, studentId);
      if (context.mounted) {
        if (code == 200) {
          feedBackController.clear();
          selectedFeedbackIndex = null;
          setState(() {
            Utils.snackBar("successFeedback".tr, context);
          });
        } else {
          print("Feedback send error : ${viewModel.apiError}");
          Utils.snackBar("${viewModel.apiError}", context);
        }
      }
    }
  }

  String formatDate(String dateString) {
    DateTime parsedDate =
        DateTime.parse(dateString); // Parse the string into DateTime
    return DateFormat('dd-MM-yyyy')
        .format(parsedDate); // Format it as dd-MM-yyyy
  }
}
