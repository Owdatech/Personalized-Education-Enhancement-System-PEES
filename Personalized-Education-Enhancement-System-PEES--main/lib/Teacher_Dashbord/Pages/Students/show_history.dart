import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Teacher_Dashbord/Models/exam_history_model.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/pdf_ocr_show.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/show_evalueated_text_screen.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';

class ShowHistoryScreen extends StatefulWidget {
  String? studId;
  ShowHistoryScreen({this.studId, super.key});

  @override
  State<ShowHistoryScreen> createState() => _ShowHistoryScreenState();
}

class _ShowHistoryScreenState extends State<ShowHistoryScreen> {
  TeacherService viewModel = TeacherService();
  List<ExamHistory> examHistoryList = [];
  ExamHistory? model;

  fetchDetails() async {
    List<ExamHistory>? examHistoryModel =
        await viewModel.fetchExamHistory(widget.studId ?? "");
    if (examHistoryModel != null) {
      model = examHistoryModel.first;
      examHistoryList = examHistoryModel;
    }
  }

  deleteAction(String evaluatedId) async {
    print("Evaluated Id = ${evaluatedId}");
    int? code =
        await viewModel.deleteEvaluation(widget.studId ?? "", evaluatedId);
    if (code == 200) {
      print("Success delete");
      Utils.snackBar("successDelete".tr, context);
      Navigator.pop(context);
      fetchDetails();
    } else {
      print("error evaluation delete : ${viewModel.apiError}");
    }
  }

  showConrifmation(String evaluatedId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("deleteEvaluationTitle".tr),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("no".tr)),
                TextButton(
                    onPressed: () {
                      deleteAction(evaluatedId);
                    },
                    child: Text("yes".tr)),
              ],
            ));
  }

  @override
  void initState() {
    // fetchDetails();
    super.initState();
  }

  int? selectedIndex;
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
                        isMobile ? const BackButtonWidget() : const SizedBox(),
                        SizedBox(height: isMobile ? 5 : 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "examHistoryTitle".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: FutureBuilder<List<ExamHistory>>(
                            future:
                                viewModel.fetchExamHistory(widget.studId ?? ""),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child:
                                        CircularProgressIndicator()); // Loading state
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text("erroExamHistory".tr));
                              } else if (snapshot.hasData &&
                                  snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text("noExamHistory"
                                        .tr)); // Handle 404 response
                              } else {
                                List<ExamHistory> exams = snapshot.data!;
                                return ListView.builder(
                                  itemCount: exams.length,
                                  itemBuilder: (context, index) {
                                    // DateTime date =
                                    //     DateTime.parse(exams[index].date);
                                    // String datFormat =
                                    //     DateFormat("dd-MM-yyyy").format(date);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: AppColor.panelDarkSoft,
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: AppColor.greyShadow,
                                                  offset: Offset(0, 5),
                                                  blurRadius: 5)
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 10),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text("examName".tr,
                                                            style: NotoSansArabicCustomTextStyle
                                                                .bold
                                                                .copyWith(
                                                                    fontSize:
                                                                        14,
                                                                    color: AppColor
                                                                        .black)),
                                                        const SizedBox(
                                                            width: 7),
                                                        Text(
                                                            exams[index]
                                                                .examName,
                                                            style: NotoSansArabicCustomTextStyle
                                                                .medium
                                                                .copyWith(
                                                                    fontSize:
                                                                        13,
                                                                    color: AppColor
                                                                        .black)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                            "${"subject".tr} : ",
                                                            style: NotoSansArabicCustomTextStyle
                                                                .bold
                                                                .copyWith(
                                                                    fontSize:
                                                                        14,
                                                                    color: AppColor
                                                                        .black)),
                                                        const SizedBox(
                                                            width: 7),
                                                        Text(
                                                            exams[index]
                                                                .subjectName,
                                                            style: NotoSansArabicCustomTextStyle
                                                                .medium
                                                                .copyWith(
                                                                    fontSize:
                                                                        13,
                                                                    color: AppColor
                                                                        .black))
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                            "${"curriculumName".tr} : ",
                                                            style: NotoSansArabicCustomTextStyle
                                                                .bold
                                                                .copyWith(
                                                                    fontSize:
                                                                        14,
                                                                    color: AppColor
                                                                        .black)),
                                                        const SizedBox(
                                                            width: 7),
                                                        Text(
                                                            exams[index]
                                                                .curriculumName,
                                                            style: NotoSansArabicCustomTextStyle
                                                                .medium
                                                                .copyWith(
                                                                    fontSize:
                                                                        13,
                                                                    color: AppColor
                                                                        .black))
                                                      ],
                                                    ),
                                                    isMobile
                                                        ? Row(
                                                            children: [
                                                              Text(
                                                                  "${"examDate".tr} : ",
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .bold
                                                                      .copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black)),
                                                              Text(
                                                                  exams[index]
                                                                      .date,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .medium
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black)),
                                                            ],
                                                          )
                                                        : const SizedBox(),
                                                    isMobile
                                                        ? Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Row(
                                                              children: [
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      // alertshow(
                                                                      //     context,
                                                                      //     exams[index]
                                                                      //         .curriculumName,
                                                                      //     exams[index]
                                                                      //         .evaluatedText);
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => EvaluatedScreen(text: exams[index].evaluatedText)));
                                                                    },
                                                                    style: TextButton.styleFrom(
                                                                        side: const BorderSide(
                                                                            width:
                                                                                0.8,
                                                                            color: AppColor
                                                                                .buttonGreen)),
                                                                    child: Text(
                                                                        "showEvaluatedText"
                                                                            .tr,
                                                                        style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                AppColor.buttonGreen))),
                                                              ],
                                                            ),
                                                          )
                                                        : const SizedBox(),
                                                    isMobile
                                                        ? SizedBox(height: 4)
                                                        : SizedBox(),
                                                    isMobile
                                                        ? TextButton(
                                                            onPressed: () {
                                                              showConrifmation(
                                                                  exams[index]
                                                                      .evaluatedId);
                                                            },
                                                            style: TextButton.styleFrom(
                                                                side: const BorderSide(
                                                                    width: 0.8,
                                                                    color: Colors
                                                                        .red)),
                                                            child: Text(
                                                                "delete".tr,
                                                                style: NotoSansArabicCustomTextStyle
                                                                    .bold
                                                                    .copyWith(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .red)))
                                                        : const SizedBox()
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    isMobile
                                                        ? const SizedBox()
                                                        : Row(
                                                            children: [
                                                              Text(
                                                                  "${"examDate".tr} : ",
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .bold
                                                                      .copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black)),
                                                              Text(
                                                                  exams[index]
                                                                      .date,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .medium
                                                                      .copyWith(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              AppColor.black)),
                                                            ],
                                                          ),
                                                    const SizedBox(height: 7),
                                                    isMobile
                                                        ? const SizedBox()
                                                        : Row(
                                                            children: [
                                                              TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                EvaluatedScreen(text: exams[index].evaluatedText)));
                                                                  },
                                                                  style: TextButton.styleFrom(
                                                                      side: const BorderSide(
                                                                          width:
                                                                              0.8,
                                                                          color: AppColor
                                                                              .buttonGreen)),
                                                                  child: Text(
                                                                      "showEvaluatedText"
                                                                          .tr,
                                                                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.buttonGreen))),
                                                              const SizedBox(
                                                                  width: 7),
                                                              isMobile
                                                                  ? const SizedBox()
                                                                  : TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        showConrifmation(
                                                                            exams[index].evaluatedId);
                                                                      },
                                                                      style: TextButton.styleFrom(
                                                                          side: const BorderSide(
                                                                              width:
                                                                                  0.8,
                                                                              color: Colors
                                                                                  .red)),
                                                                      child: Text(
                                                                          "delete"
                                                                              .tr,
                                                                          style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                              fontSize: 14,
                                                                              color: Colors.red)))
                                                            ],
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  value.loading ? const LoaderView() : Container()
                ],
              )),
            );
          });
        }));
  }

  // void alertshow(BuildContext context, String title, String text) {
  //   if (!context.mounted) return;
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         backgroundColor: AppColor.white,
  //         title: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 title,
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 // style: NotoSansArabicCustomTextStyle.bold
  //                 //     .copyWith(fontSize: 15, color: AppColor.buttonGreen),
  //               ),
  //             ),
  //             InkWell(
  //               onTap: () {
  //                 Navigator.pop(dialogContext);
  //               },
  //               child: const Icon(Icons.cancel, color: Colors.red),
  //             ),
  //           ],
  //         ),
  //         content: SingleChildScrollView(
  //           child: MarkdownBody(
  //             data: text,
  //             selectable: true,
  //             extensionSet: md.ExtensionSet(
  //               md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  //               [
  //                 LatexInlineSyntax(),
  //                 ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
  //               ],
  //             ),
  //             builders: {
  //               "latex":
  //                   LatexElementBuilder(textDirection: ui.TextDirection.ltr),
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
