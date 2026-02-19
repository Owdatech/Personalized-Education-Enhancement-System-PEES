import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllFeedbackScreen extends StatefulWidget {
  String? planId;
  AllFeedbackScreen({this.planId, super.key});

  @override
  State<AllFeedbackScreen> createState() => _AllFeedbackScreenState();
}

class _AllFeedbackScreenState extends State<AllFeedbackScreen> {
  TeacherService viewModel = TeacherService();

  fetchFeedbacks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    String planId = widget.planId ?? "";
    print("Teacher ID : $teacherId");
    print("PlanId : $planId");
    int? code = await viewModel.fetchFeedbacks(teacherId ?? "", planId);
    if (code == 200) {
      print("Feedback Successfully Fetch");
    } else {
      print("Feedback List Error :  ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchFeedbacks();
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
              body: SafeArea(
                child: Stack(
                  children: [
                    isMobile ? SizedBox() : const BackButtonWidget(),
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
                              "feedbacks".tr,
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
                            child: viewModel.feedbackList.isEmpty
                                ? const Center(
                                    child: Text("noFeedbakcs"),
                                  )
                                : ListView.builder(
                                    itemCount: viewModel.feedbackList.length,
                                    itemBuilder: (context, index) {
                                      final feedback =
                                          viewModel.feedbackList[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 7),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              color: themeManager.isHighContrast
                                                  ? AppColor.labelText
                                                  : AppColor.white,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 5),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "date".tr,
                                                        style: NotoSansArabicCustomTextStyle
                                                            .bold
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black),
                                                      ),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        "${feedback['timestamp']}",
                                                        style: NotoSansArabicCustomTextStyle
                                                            .regular
                                                            .copyWith(
                                                                fontSize: 14,
                                                                color: AppColor
                                                                    .black),
                                                      )
                                                    ]),
                                                const SizedBox(height: 5),
                                                Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "${"feedbackMessage".tr} :",
                                                        style: NotoSansArabicCustomTextStyle
                                                            .bold
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Expanded(
                                                        child: Text(
                                                          "${feedback["feedback"]}",
                                                          textAlign:
                                                              TextAlign.start,
                                                          softWrap: true,
                                                          style: NotoSansArabicCustomTextStyle
                                                              .regular
                                                              .copyWith(
                                                                  fontSize: 14,
                                                                  color: AppColor
                                                                      .black),
                                                        ),
                                                      )
                                                    ]),
                                                const SizedBox(height: 5),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          )
                        ],
                      ),
                    ),
                    value.loading ? LoaderView() : Container(),
                  ],
                ),
              ),
            );
          });
        }));
  }
}
