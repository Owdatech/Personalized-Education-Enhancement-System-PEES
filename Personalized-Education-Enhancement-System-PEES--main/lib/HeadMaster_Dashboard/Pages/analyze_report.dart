import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';

class AnalyzeReportScreen extends StatefulWidget {
  String? studentId;
  AnalyzeReportScreen({this.studentId, super.key});

  @override
  State<AnalyzeReportScreen> createState() => _AnalyzeReportScreenState();
}

class _AnalyzeReportScreenState extends State<AnalyzeReportScreen> {
  TeacherService viewModel = TeacherService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  fetchAnalyzeData() async {
    int? code = await viewModel.analyzeStudentData(
        widget.studentId ?? "", selectedLanguage);
    if (code == 200) {
      print("Analyze data fetch successfully");
    } else {
      print("Analyze data Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchAnalyzeData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return Scaffold(
            body: Stack(
              children: [
                const BackButtonWidget(),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 100, right: 100, top: 30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "analyzeReport".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18, color: AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(15)),
                            child: viewModel.analysisData.isNotEmpty &&
                                    hasValidData(viewModel.analysisData)
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildAnalysisSection(
                                          "recommendations",
                                          viewModel
                                              .analysisData['recommendations']),
                                      buildAnalysisSection("strengths",
                                          viewModel.analysisData['strengths']),
                                      buildAnalysisSection("weaknesses",
                                          viewModel.analysisData['weaknesses']),
                                      buildAnalysisSection(
                                          "interventions",
                                          viewModel
                                              .analysisData['interventions']),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        "No data found.",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  )),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                viewModel.loading ? const LoaderView() : Container()
              ],
            ),
          );
        }));
  }

  bool hasValidData(Map<String, dynamic> data) {
    final sections = [
      'recommendations',
      'strengths',
      'weaknesses',
      'interventions'
    ];
    for (var section in sections) {
      if (data.containsKey(section)) {
        final content = data[section];
        if (content != null && content is List && content.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  Widget buildAnalysisSection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.tr,
            style: NotoSansArabicCustomTextStyle.bold
                .copyWith(fontSize: 17, color: AppColor.black),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text("- $item",
                    style: NotoSansArabicCustomTextStyle.regular
                        .copyWith(fontSize: 15, color: AppColor.black)),
              )),
        ],
      ),
    );
  }
}
