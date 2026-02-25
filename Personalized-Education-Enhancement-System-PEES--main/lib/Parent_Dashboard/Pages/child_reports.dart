import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Parent_Dashboard/Models/parent_model.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:html' as html;

class ChildsReportScreen extends StatefulWidget {
  String studentId;
  String userName;
  String photoUrl;
  String teacherName;
  String grade;
  String className;
  String email;
  ChildsReportScreen(
      {required this.studentId,
      required this.userName,
      required this.photoUrl,
      required this.teacherName,
      required this.grade,
      required this.className,
      required this.email,
      super.key});

  @override
  State<ChildsReportScreen> createState() => _ChildsReportScreenState();
}

class _ChildsReportScreenState extends State<ChildsReportScreen> {
  ParentService viewModel = ParentService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  ProgressModel? model;

  fetchChildDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? parentId = prefs.getString('userId');
    String? studentId = widget.studentId;
    print("StudentID : ${widget.studentId}");
    ProgressModel? progressModel =
        await viewModel.fetchProgressReport(parentId ?? "", studentId);
    if (progressModel != null) {
      setState(() {
        model = progressModel;
      });
    }
  }

  void downloadPDFFile(String url) async {
    // final anchorElement = html.AnchorElement(href: url)
    //   ..setAttribute("download", "ProgressReport.pdf")
    //   ..click();

    // html.Url.revokeObjectUrl(url);
    html.window.open(url, "ProgressReport.pdf");
  }

  @override
  void initState() {
    fetchChildDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<ParentService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<ParentService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.bgLavender,
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 100,
                        top: 30),
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColor.panelDarkSoft,
                          borderRadius: BorderRadius.circular(7),
                          border:
                              Border.all(color: AppColor.lightGrey, width: 1)),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            isMobile
                                ? SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        headView(),
                                        const SizedBox(height: 15),

                                        // subjectChart(),
                                        // const SizedBox(height: 15),
                                        // gradeChart(),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(25.0),
                                    child: Column(
                                      children: [
                                        headView(),
                                        const SizedBox(height: 15),
                                      ],
                                    ),
                                  )
                          ],
                        ),
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

  bool isShowDetails = false;
  headView() {
    return Container(
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 10,
                offset: Offset(3, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(widget.photoUrl),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.userName,
                  style: NotoSansArabicCustomTextStyle.semibold
                      .copyWith(fontSize: 16, color: AppColor.text),
                )
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text("${"email".tr} ",
                    style: NotoSansArabicCustomTextStyle.semibold
                        .copyWith(fontSize: 15, color: AppColor.text)),
                Text(widget.email,
                    style: NotoSansArabicCustomTextStyle.medium
                        .copyWith(color: AppColor.text, fontSize: 14))
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text("${"class".tr} : ",
                    style: NotoSansArabicCustomTextStyle.semibold
                        .copyWith(fontSize: 15, color: AppColor.text)),
                Text(widget.className,
                    style: NotoSansArabicCustomTextStyle.medium
                        .copyWith(color: AppColor.text, fontSize: 14))
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text("${"grade".tr} : ",
                    style: NotoSansArabicCustomTextStyle.semibold
                        .copyWith(fontSize: 15, color: AppColor.text)),
                Text(widget.grade,
                    style: NotoSansArabicCustomTextStyle.medium
                        .copyWith(color: AppColor.text, fontSize: 14))
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text("${"assignedTeacherName".tr} : ",
                    style: NotoSansArabicCustomTextStyle.semibold
                        .copyWith(fontSize: 15, color: AppColor.text)),
                Text(widget.teacherName,
                    style: NotoSansArabicCustomTextStyle.medium
                        .copyWith(color: AppColor.text, fontSize: 14))
              ],
            ),
            const SizedBox(height: 7),
            AppFillButton3(
                onPressed: () {
                  downloadPDFFile(model!.pdfUrl!);
                },
                text: "viewDetails",
                color: AppColor.buttonGreen),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  List<SubjectModel> subjectsData = [
    SubjectModel(subjectName: "Maths", marks: 85),
    SubjectModel(subjectName: "English", marks: 70),
    SubjectModel(subjectName: "Science", marks: 90),
  ];

  subjectChart() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // height: 200,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
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
                  "subjectPerformance".tr,
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
              height: 275,
              width: 470,
              child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis:
                      const NumericAxis(minimum: 0, maximum: 100, interval: 20),
                  series: <CartesianSeries>[
                    ColumnSeries<SubjectModel, String>(
                        dataSource: subjectsData,
                        xValueMapper: (SubjectModel data, _) =>
                            data.subjectName,
                        // pointColorMapper: (SubjectModel data, _) =>
                        //     data.color,
                        width: subjectsData.length == 1 ? 0.3 : 0.8,
                        spacing: subjectsData.length == 1 ? 0.5 : 0.2,
                        dataLabelSettings: const DataLabelSettings(
                            textStyle: TextStyle(fontSize: 10)),
                        yValueMapper: (SubjectModel data, _) => data.marks)
                  ]),
            ),
          )
        ],
      ),
    );
  }

  List<GradeModel> gradeData = [
    GradeModel(date: "10-3-2025", grade: 5),
    GradeModel(date: "12-3-2025", grade: 8),
    GradeModel(date: "15-3-2025", grade: 3),
  ];

  gradeChart() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // height: 200,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
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
                  "grade".tr,
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
              height: 275,
              width: 470,
              child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis:
                      const NumericAxis(minimum: 6, maximum: 10, interval: 1),
                  series: <LineSeries<GradeModel, String>>[
                    LineSeries<GradeModel, String>(
                      dataSource: gradeData,
                      xValueMapper: (GradeModel data, _) => data.date,
                      yValueMapper: (GradeModel data, _) => data.grade,
                      markerSettings: const MarkerSettings(
                          isVisible: true,
                          shape: DataMarkerType.circle,
                          width: 6,
                          height: 6),
                    )
                  ]),
            ),
          )
        ],
      ),
    );
  }
}

class GradeModel {
  String? date;
  int? grade;

  GradeModel({this.date, this.grade});
}

class SubjectModel {
  String? subjectName;
  int? marks;

  SubjectModel({this.subjectName, this.marks});
}
