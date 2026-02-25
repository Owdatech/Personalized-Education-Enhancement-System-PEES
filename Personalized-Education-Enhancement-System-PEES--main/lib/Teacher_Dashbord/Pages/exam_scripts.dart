// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/custom_style.dart';

class ExamScriptsScreen extends StatefulWidget {
  const ExamScriptsScreen({super.key});

  @override
  State<ExamScriptsScreen> createState() => _ExamScriptsScreenState();
}

class _ExamScriptsScreenState extends State<ExamScriptsScreen> {
  TextEditingController dateController = TextEditingController();
  TeacherService viewModel = TeacherService();
  List<String> examNameList = [];
  String? examName;
  List<String> curriculumList = [];

  String? curriculumName;
  DateTime? _selectedDate;
  TextEditingController engMarksController = TextEditingController();
  TextEditingController mathMarksController = TextEditingController();
  TextEditingController sciMarksController = TextEditingController();
  TextEditingController historyMarksController = TextEditingController();
  TextEditingController gkMarksController = TextEditingController();
  TextEditingController compMarksController = TextEditingController();
  TextEditingController drwaMarksController = TextEditingController();
  TextEditingController busStuMarksController = TextEditingController();
  TextEditingController ecoMarksController = TextEditingController();

  TextEditingController engGradeController = TextEditingController();
  TextEditingController mathGradeController = TextEditingController();
  TextEditingController sciGradeController = TextEditingController();
  TextEditingController historyGradeController = TextEditingController();
  TextEditingController gkGradeController = TextEditingController();
  TextEditingController compGradeController = TextEditingController();
  TextEditingController drwaGradeController = TextEditingController();
  TextEditingController busStuGradeController = TextEditingController();
  TextEditingController ecoGradeController = TextEditingController();

  TextEditingController workingController = TextEditingController();
  TextEditingController presentController = TextEditingController();
  TextEditingController absentController = TextEditingController();
  TextEditingController halfController = TextEditingController();

  _selectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
        _selectedDate = newSelectedDate;
      });
      dateController
        ..text = DateFormat('dd-MM-yyyy').format(_selectedDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: dateController.text.length,
            affinity: TextAffinity.upstream));
    }
  }

  discardAction() {}

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 800;
    return Scaffold(
      backgroundColor: AppColor.bgLavender,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    // height: MediaQuery.of(context).size.height,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: isMobile ? 12 : 70,
                          right: isMobile ? 12 : 70,
                          top: isMobile ? 16 : 44),
                      child: Column(
                        children: [
                          dropDownBox(),
                          const SizedBox(height: 20),
                          Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColor.white,
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 15,
                                        color: AppColor.greyShadow,
                                        offset: Offset(0, 15))
                                  ]),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: 30,
                                    left: isMobile ? 12 : 70,
                                    right: isMobile ? 12 : 70),
                                child: Column(
                                  children: [
                                    userDetails(isMobile),
                                    const SizedBox(height: 25),
                                    topTabBar(),
                                    viewModel.selectedExamTab ==
                                            ExamScriptFor.academic
                                        ? academicTable(isMobile)
                                        : formView(isMobile),
                                    const SizedBox(height: 10),
                                    viewModel.selectedExamTab ==
                                            ExamScriptFor.academic
                                        ? Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            alignment: WrapAlignment.end,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  discardAction();
                                                },
                                                child: Container(
                                                  height: 40,
                                                  width: 150,
                                                  decoration: BoxDecoration(
                                                      color: AppColor
                                                          .panelDarkSoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                          width: 1,
                                                          color: AppColor
                                                              .buttonGreen)),
                                                  child: Center(
                                                    child: Text(
                                                      "discard".tr,
                                                      style: PoppinsCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize: 18,
                                                              color: AppColor
                                                                  .buttonGreen),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              AppFillButton3(
                                                onPressed: () {},
                                                text: "examScript",
                                                color: AppColor.buttonGreen,
                                              ),
                                              AppFillButton3(
                                                  onPressed: () {},
                                                  text: "save",
                                                  color: AppColor.buttonGreen),
                                            ],
                                          )
                                        : const SizedBox(),
                                    const SizedBox(height: 30)
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget academicTable(bool isMobile) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 0 : 475),
      decoration: const BoxDecoration(
          color: AppColor.extralightGrey,
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5))),
      child: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isMobile ? 320 : 453,
                        height: 38,
                        decoration: const BoxDecoration(
                            color: AppColor.buttonGreen,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("subject".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: 13, color: AppColor.white)),
                              Row(
                                children: [
                                  Text("marks".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize: 13,
                                              color: AppColor.white)),
                                  const SizedBox(width: 25),
                                  Text("gradee".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize: 13,
                                              color: AppColor.white)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      subjectTable(isMobile),
                    ],
                  ),
                  SizedBox(width: isMobile ? 20 : 70),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Column(
                      children: [
                        attendance(isMobile),
                        const SizedBox(height: 45),
                        curriculumRelevance(isMobile)
                      ],
                    ),
                  )
                ],
              ),
            ),
            Container(
              width: 120,
              height: 25,
              decoration: BoxDecoration(
                  color: AppColor.buttonGreen,
                  borderRadius: BorderRadius.circular(5)),
              child: Center(
                child: Text(
                  "addSubject".tr,
                  style: PoppinsCustomTextStyle.medium
                      .copyWith(fontSize: 15, color: AppColor.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget attendance(bool isMobile) {
    return SizedBox(
      height: 175,
      width: isMobile ? 280 : 300,
      child: Column(
        children: [
          Container(
            height: 20,
            width: isMobile ? 280 : 300,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Center(
              child: Text("attendance".tr,
                  style: PoppinsCustomTextStyle.medium
                      .copyWith(color: AppColor.white, fontSize: 13)),
            ),
          ),
          Container(
            height: 155,
            width: isMobile ? 280 : 300,
            decoration: const BoxDecoration(
                color: AppColor.panelDarkSoft,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  attendanceDetails("totalWorkingDay".tr, workingController),
                  const SizedBox(height: 10),
                  attendanceDetails("presentDays".tr, presentController),
                  const SizedBox(height: 10),
                  attendanceDetails("absentDays".tr, absentController),
                  const SizedBox(height: 10),
                  attendanceDetails("halfDay".tr, halfController),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget curriculumRelevance(bool isMobile) {
    return SizedBox(
      height: 175,
      width: isMobile ? 280 : 300,
      child: Column(
        children: [
          Container(
            height: 20,
            width: isMobile ? 280 : 300,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Center(
              child: Text("curriculumCoverage".tr,
                  style: PoppinsCustomTextStyle.medium
                      .copyWith(color: AppColor.white, fontSize: 13)),
            ),
          ),
          Container(
            height: 155,
            width: isMobile ? 280 : 300,
            decoration: const BoxDecoration(
                color: AppColor.panelDarkSoft,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: Column(
              children: [
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    "multiselectdropdown".tr,
                    style: NotoSansArabicCustomTextStyle.regular
                        .copyWith(color: AppColor.black, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                        value: false,
                        onChanged: (value) {},
                        side:
                            BorderSide(color: AppColor.buttonGreen, width: 1)),
                    Checkbox(
                        value: false,
                        onChanged: (value) {},
                        side:
                            BorderSide(color: AppColor.buttonGreen, width: 1)),
                    Checkbox(
                        value: false,
                        onChanged: (value) {},
                        side:
                            BorderSide(color: AppColor.buttonGreen, width: 1)),
                    Checkbox(
                        value: false,
                        onChanged: (value) {},
                        side:
                            BorderSide(color: AppColor.buttonGreen, width: 1)),
                    Checkbox(
                        value: false,
                        onChanged: (value) {},
                        side:
                            BorderSide(color: AppColor.buttonGreen, width: 1)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget attendanceDetails(String text, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          text,
          style: NotoSansArabicCustomTextStyle.bold
              .copyWith(fontSize: 13, color: AppColor.black),
        ),
        Container(
          height: 20,
          width: 86,
          decoration: BoxDecoration(
              color: AppColor.panelDarkSoft,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(width: 1, color: AppColor.textGrey)),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: PoppinsCustomTextStyle.medium
                .copyWith(color: AppColor.black, fontSize: 10),
            decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsetsDirectional.only(start: 5, bottom: 22)),
          ),
        ),
      ]),
    );
  }

  Widget subjectTable(bool isMobile) {
    return Column(
      children: [
        subjectItem(
            "English", engMarksController, engGradeController, isMobile),
        subjectItem("Math", mathMarksController, mathGradeController, isMobile),
        subjectItem(
            "Science", sciMarksController, sciGradeController, isMobile),
        subjectItem("History", historyMarksController, historyGradeController,
            isMobile),
        subjectItem("GK", gkMarksController, gkGradeController, isMobile),
        subjectItem(
            "Computer", compMarksController, compGradeController, isMobile),
        subjectItem(
            "Drawing", drwaMarksController, drwaGradeController, isMobile),
        subjectItem("Business Studies", busStuMarksController,
            busStuGradeController, isMobile),
        subjectItem(
            "Economics", ecoMarksController, ecoGradeController, isMobile),
      ],
    );
  }

  Widget subjectItem(String text, TextEditingController marksController,
      TextEditingController gradeController, bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 220 : 314,
          height: 38,
          decoration: BoxDecoration(
              color: AppColor.panelDarkSoft,
              border: Border.all(width: 1, color: AppColor.buttonGreen)),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 23),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: NotoSansArabicCustomTextStyle.bold
                    .copyWith(fontSize: 13, color: AppColor.black),
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 25),
        Container(
          height: 36,
          width: isMobile ? 48 : 36,
          decoration: BoxDecoration(
            color: AppColor.panelDarkSoft,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColor.buttonGreen, width: 1),
          ),
          child: TextField(
            textAlign: TextAlign.center,
            controller: marksController,
            style: PoppinsCustomTextStyle.medium
                .copyWith(color: AppColor.black, fontSize: 15),
            decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(bottom: 10),
                border: InputBorder.none),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 25),
        Container(
          height: 36,
          width: isMobile ? 48 : 36,
          decoration: BoxDecoration(
            color: AppColor.panelDarkSoft,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColor.buttonGreen, width: 1),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextField(
              textAlign: TextAlign.center,
              controller: gradeController,
              style: PoppinsCustomTextStyle.medium
                  .copyWith(color: AppColor.black, fontSize: 15),
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(bottom: 10),
                  border: InputBorder.none),
            ),
          ),
        )
      ],
    );
  }

  Widget userDetails(bool isMobile) {
    final detailsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Alex",
            style: NotoSansArabicCustomTextStyle.bold
                .copyWith(fontSize: 18, color: AppColor.black)),
        const SizedBox(height: 15),
        Wrap(
          spacing: isMobile ? 10 : 100,
          runSpacing: 6,
          children: [
            Text("${"studentId".tr} : XYZ123456",
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.black)),
            Text("${"class/section".tr} : 10th",
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.black)),
          ],
        ),
        const SizedBox(height: 15),
        Text("contactInformation".tr,
            style: NotoSansArabicCustomTextStyle.semibold
                .copyWith(fontSize: 15, color: AppColor.black)),
        const SizedBox(height: 15),
        Wrap(
          spacing: isMobile ? 10 : 100,
          runSpacing: 6,
          children: [
            Text("${"phoneNumber".tr} : +911234567890",
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.black)),
            Text("${"email".tr} : abcd@gmail.com",
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.black))
          ],
        ),
        const SizedBox(height: 5),
        Text("${"address".tr} : XYZ City, USA",
            style: NotoSansArabicCustomTextStyle.medium
                .copyWith(fontSize: 13, color: AppColor.black))
      ],
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          detailsColumn,
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColor.lightGrey)),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailsColumn,
        Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColor.lightGrey)),
      ],
    );
  }

  Widget dropDownBox() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 15, end: 8),
              child: Text(
                "searchHint".tr,
                overflow: TextOverflow.ellipsis,
                style: NotoSansArabicCustomTextStyle.bold
                    .copyWith(color: AppColor.labelText, fontSize: 18),
              ),
            ),
          ),
          Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadiusDirectional.only(
                  bottomEnd: Radius.circular(10),
                  topEnd: Radius.circular(10),
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

  Widget formView(bool isMobile) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 0 : 500),
      decoration: const BoxDecoration(
          color: AppColor.extralightGrey,
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5))),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Wrap(
              runSpacing: 10,
              spacing: 20,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("examName".tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(fontSize: 13, color: AppColor.black)),
                    const SizedBox(width: 10),
                    examNameTextField(),
                  ],
                ),
                Row(
                  children: [
                    Text("date".tr,
                        style: NotoSansArabicCustomTextStyle.medium
                            .copyWith(fontSize: 13, color: AppColor.black)),
                    const SizedBox(width: 10),
                    SizedBox(
                        height: 25,
                        width: 250,
                        child: AppFillTextField(
                            textController: dateController,
                            readOnly: true,
                            suffixIcon: IconButton(
                                onPressed: () {
                                  _selectDate(context);
                                },
                                padding:
                                    const EdgeInsetsDirectional.only(start: 15),
                                icon: Image.asset(
                                  AppImage.calendar,
                                  width: 45,
                                )),
                            hintText: "selectDate".tr,
                            icon: null)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("curriculumCoverage".tr,
                          style: NotoSansArabicCustomTextStyle.medium
                              .copyWith(fontSize: 13, color: AppColor.black)),
                      const SizedBox(height: 10),
                      crriculumTextField()
                    ],
                  )
                : Row(
                    children: [
                      Text("curriculumCoverage".tr,
                          style: NotoSansArabicCustomTextStyle.medium
                              .copyWith(fontSize: 13, color: AppColor.black)),
                      const SizedBox(width: 10),
                      crriculumTextField()
                    ],
                  ),
            const SizedBox(height: 20),
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColor.panelDarkSoft,
                  borderRadius: BorderRadius.circular(5)),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("uploadFiles".tr,
                        style: PoppinsCustomTextStyle.semibold
                            .copyWith(fontSize: 18, color: AppColor.black)),
                    const SizedBox(height: 5),
                    Text("dragandDropFiles".tr,
                        style: PoppinsCustomTextStyle.medium
                            .copyWith(fontSize: 13, color: AppColor.black)),
                    const SizedBox(height: 5),
                    Text("supportedFileTypesPDF,JPG".tr,
                        style: PoppinsCustomTextStyle.regular
                            .copyWith(fontSize: 10, color: AppColor.black)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppFillButton3(
                    onPressed: () {},
                    text: "upload",
                    color: AppColor.buttonGreen)),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text("notesandObservations".tr,
                  style: PoppinsCustomTextStyle.semibold
                      .copyWith(fontSize: 18, color: AppColor.black)),
            ),
            const SizedBox(height: 20),
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColor.panelDarkSoft,
                  borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 7, start: 17),
                child: Text("notesHint".tr,
                    style: PoppinsCustomTextStyle.medium
                        .copyWith(fontSize: 13, color: AppColor.black)),
              ),
            ),
            const SizedBox(height: 20),
            Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppFillButton3(
                    onPressed: () {},
                    text: "submit",
                    color: AppColor.buttonGreen)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget crriculumTextField() {
    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton(
          hint: Padding(
            padding: const EdgeInsetsDirectional.only(start: 15, top: 1),
            child: Text("multiselectdropdown".tr,
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 5),
            child: Image.asset(
              AppImage.arrowDown,
              width: 16,
            ),
          ),
          isExpanded: true,
          value: curriculumName,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              curriculumName = value.toString();
            });
          },
          items: curriculumList.map((value) {
            return DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 1, start: 10),
                  child: Text(
                    value,
                    style: NotoSansArabicCustomTextStyle.regular
                        .copyWith(color: AppColor.text, fontSize: 14),
                  ),
                ));
          }).toList(),
        ),
      ),
    );
  }

  Widget examNameTextField() {
    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton(
          hint: Padding(
            padding: const EdgeInsetsDirectional.only(start: 15, top: 1),
            child: Text("examNameTitle".tr,
                style: NotoSansArabicCustomTextStyle.medium
                    .copyWith(fontSize: 13, color: AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 5),
            child: Image.asset(
              AppImage.arrowDown,
              width: 16,
            ),
          ),
          isExpanded: true,
          value: examName,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              examName = value.toString();
            });
          },
          items: examNameList.map((value) {
            return DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 1, start: 10),
                  child: Text(
                    value,
                    style: NotoSansArabicCustomTextStyle.regular
                        .copyWith(color: AppColor.text, fontSize: 14),
                  ),
                ));
          }).toList(),
        ),
      ),
    );
  }

  Widget topTabBar() {
    return Center(
        child: Row(
      children: [
        tabTitle("academicData", ExamScriptFor.academic, 0),
        tabTitle("examScript", ExamScriptFor.examScript, 1),
      ],
    ));
  }

  changeTabAction(ExamScriptFor type) async {
    viewModel.selectedExamTab = type;
    if (viewModel.selectedExamTab == ExamScriptFor.academic) {
    } else {}
  }

  tabTitle(text, ExamScriptFor type, int selectedItem) {
    bool isSelected = type == viewModel.selectedExamTab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            changeTabAction(type);
            viewModel.selectedScripts = selectedItem;
          });
        },
        child: Container(
          width: 460,
          height: 40,
          decoration: BoxDecoration(
              color: isSelected == true
                  ? AppColor.buttonGreen
                  : AppColor.lightYellow,
              borderRadius: BorderRadius.only(
                  topLeft:
                      Radius.circular(type == ExamScriptFor.academic ? 5 : 0),
                  topRight:
                      Radius.circular(type == ExamScriptFor.academic ? 0 : 5))),
          child: Center(
            child: Text("$text".tr,
                style: PoppinsCustomTextStyle.bold.copyWith(
                    fontSize: 18,
                    color: isSelected ? AppColor.white : AppColor.buttonGreen)),
          ),
        ),
      ),
    );
  }
}
